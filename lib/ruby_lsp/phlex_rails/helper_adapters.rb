# frozen_string_literal: true

module RubyLsp
	module PhlexRails
		# Rails helpers in a component that no ancestor makes available, with the
		# `Phlex::Rails::Helpers` adapter that would.
		module HelperAdapters
			NAMESPACE = "Phlex::Rails::Helpers::"

			def initialize(response_builder, index, node_context, uri, dispatcher)
				@response_builder = response_builder
				@index = index
				@node_context = node_context
				@uri = uri

				dispatcher.register(self, :on_call_node_enter)
			end

			private def missing_helpers(node, &)
				return unless node.receiver.nil?

				owner = @node_context.fully_qualified_name

				return unless component?(owner)

				yield(owner).each_with_object({}) do |entry, helpers|
					next unless RubyIndexer::Entry::Method === entry
					next unless entry.owner&.name&.start_with?(NAMESPACE)
					next if @index.resolve_method(entry.name, owner)

					helpers[entry.name] ||= entry.owner.name
				end
			end

			private def component?(owner)
				@index.linearized_ancestors_of(owner).include?("Phlex::SGML")
			rescue RubyIndexer::Index::NonExistingNamespaceError
				false
			end
		end

		class HelperAdapterCompletion
			include HelperAdapters

			def on_call_node_enter(node)
				helpers = missing_helpers(node) { @index.prefix_search(node.message.to_s).flatten }
				edit = include_edit

				helpers&.each do |name, adapter|
					@response_builder << Interface::CompletionItem.new(
						label: name,
						label_details: Interface::CompletionItemLabelDetails.new(description: "include #{adapter}"),
						kind: Constant::CompletionItemKind::METHOD,
						additional_text_edits: (edit ? [edit.call(adapter)] : nil),
					)
				end
			end

			# Inserts the include on the line after the class keyword, indented like
			# the class on disk, or with tabs for a file that isn't saved yet.
			private def include_edit
				path = @uri.full_path
				entry = @index[@node_context.fully_qualified_name]&.find { |entry| entry.uri.full_path == path }

				return unless entry

				line = entry.location.start_line
				indentation = (path && File.file?(path) && File.readlines(path)[line - 1]&.[](/\A[ \t]*/)) || ("\t" * entry.location.start_column)
				unit = indentation.include?(" ") ? "  " : "\t"
				position = Interface::Position.new(line:, character: 0)

				-> (adapter) {
					Interface::TextEdit.new(
						range: Interface::Range.new(start: position, end: position),
						new_text: "#{indentation}#{unit}include #{adapter}\n",
					)
				}
			end
		end

		class HelperAdapterHover
			include HelperAdapters

			def on_call_node_enter(node)
				missing_helpers(node) { @index[node.message.to_s] || [] }&.each do |name, adapter|
					@response_builder.push("Include `#{adapter}` to use `#{name}`:\n\n```ruby\ninclude #{adapter}\n```", category: :documentation)
				end
			end
		end
	end
end
