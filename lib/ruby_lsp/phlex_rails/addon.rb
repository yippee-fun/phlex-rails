# frozen_string_literal: true

require "ruby_lsp/addon"
require_relative "definition"
require_relative "code_lens"
require_relative "helper_adapters"

module RubyLsp
	module PhlexRails
		class Addon < ::RubyLsp::Addon
			def activate(global_state, message_queue)
				@global_state = global_state
			end

			def deactivate
			end

			def name
				"PhlexRails"
			end

			def version
				"0.1.0"
			end

			def create_code_lens_listener(response_builder, uri, dispatcher)
				return unless index

				@render_sites ||= RenderSites.new(index)
				CodeLens.new(response_builder, index, @render_sites, @global_state.workspace_path, dispatcher)
			end

			def create_completion_listener(response_builder, node_context, dispatcher, uri)
				return unless index

				HelperAdapterCompletion.new(response_builder, index, node_context, uri, dispatcher)
			end

			def create_hover_listener(response_builder, node_context, dispatcher)
				return unless index

				HelperAdapterHover.new(response_builder, index, node_context, nil, dispatcher)
			end

			def create_definition_listener(response_builder, uri, node_context, dispatcher)
				Definition.new(response_builder, index, @global_state.workspace_path, node_context, dispatcher)
			end

			# ruby-lsp 0.27 replaced RubyIndexer with Rubydex, so features that need the index are off there.
			private def index
				@global_state.index if defined?(::RubyIndexer::Index)
			end
		end

		# ruby-lsp 0.27 replaced RubyIndexer with Rubydex, which has no Enhancement API.
		if defined?(::RubyIndexer::Enhancement)
			class IndexingEnhancement < RubyIndexer::Enhancement
				def on_call_node_enter(node)
					name = node.name
					owner = @listener.current_owner
					location = node.location
					arguments = node.arguments&.arguments

					return unless owner
					return unless name in :register_output_helper | :register_value_helper | :register_builder_yielding_helper

					case arguments
					in [Prism::SymbolNode[unescaped: String => method_name], *]
						@listener.add_method(method_name, location, [
							RubyIndexer::Entry::Signature.new([
								RubyIndexer::Entry::ForwardingParameter.new,
							]),
						], visibility: :public)
					else
						# no-op
					end
				end
			end
		end
	end
end
