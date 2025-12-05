# frozen_string_literal: true

require "ruby_lsp/addon"

module RubyLsp
	module PhlexRails
		class Addon < ::RubyLsp::Addon
			def activate(global_state, message_queue)
			end

			def deactivate
			end

			def name
				"PhlexRails"
			end

			def version
				"0.1.0"
			end
		end

		class IndexingEnhancement < RubyIndexer::Enhancement
			def on_call_node_enter(node)
				name = node.name
				owner = @listener.current_owner
				location = node.location
				arguments = node.arguments&.arguments

				return unless owner
				return unless name in :register_output_helper | :register_value_helper

				case arguments
				in [*, Prism::SymbolNode[unescaped: String => method_name], *]
					@listener.add_method(method_name, location, [
						RubyIndexer::Entry::Signature.new([
							RubyIndexer::Entry::ForwardingParameter.new,
						]),
					], visibility: :public)
				end
			end
		end
	end
end
