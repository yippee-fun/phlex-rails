# frozen_string_literal: true

module RubyLsp
	module PhlexRails
		# Goes from a fragment name passed to `fragments` to the `fragment` that
		# defines it, and from a `partial` path to the partial's files.
		class Definition
			include Requests::Support::Common

			def initialize(response_builder, index, workspace_path, node_context, dispatcher)
				@response_builder = response_builder
				@index = index
				@workspace_path = workspace_path
				@node_context = node_context

				dispatcher.register(self, :on_symbol_node_enter, :on_string_node_enter)
			end

			def on_symbol_node_enter(node)
				handle(node.unescaped)
			end

			def on_string_node_enter(node)
				handle(node.unescaped)
			end

			private def handle(value)
				case @node_context.call_node
				in { name: :fragments } => call
					fragment_definitions(call.receiver, value)
				in { name: :partial, receiver: nil }
					partial_definitions(value)
				else
					# no-op
				end
			end

			private def fragment_definitions(receiver, name)
				return unless @index

				class_name = case receiver
					in nil
						@node_context.fully_qualified_name
					in Prism::CallNode[name: :new, receiver: Prism::ConstantReadNode | Prism::ConstantPathNode => constant]
						@index.resolve(constant.slice, @node_context.nesting)&.first&.name
					else
						nil
				end

				return unless class_name

				namespace_entries(class_name).each do |entry|
					path = entry.uri.full_path

					next unless path && File.file?(path)

					lines = Range.new(entry.location.start_line, entry.location.end_line)

					FragmentFinder.find(Prism.parse_file(path).value, name).each do |fragment|
						next unless lines.cover?(fragment.location.start_line)

						@response_builder << Interface::LocationLink.new(
							target_uri: entry.uri.to_s,
							target_range: range_from_location(fragment.location),
							target_selection_range: range_from_location(fragment.message_loc),
						)
					end
				end
			end

			private def namespace_entries(class_name)
				@index.linearized_ancestors_of(class_name).flat_map do |ancestor|
					@index[ancestor]&.grep(RubyIndexer::Entry::Namespace) || []
				end
			rescue RubyIndexer::Index::NonExistingNamespaceError
				[]
			end

			private def partial_definitions(path)
				directory, _, name = path.rpartition("/")
				pattern = directory.empty? ? "**/_#{name}.*" : "#{directory}/_#{name}.*"

				Dir.glob(pattern, base: File.join(@workspace_path, "app/views")).sort.each do |match|
					@response_builder << Interface::LocationLink.new(
						target_uri: URI::Generic.from_path(path: File.join(@workspace_path, "app/views", match)).to_s,
						target_range: FILE_START,
						target_selection_range: FILE_START,
					)
				end
			end

			FILE_START = Interface::Range.new(
				start: Interface::Position.new(line: 0, character: 0),
				end: Interface::Position.new(line: 0, character: 0),
			)
		end

		class FragmentFinder < Prism::Visitor
			def self.find(node, name)
				new(name).tap { |finder| node.accept(finder) }.fragments
			end

			attr_reader :fragments

			def initialize(name)
				@name = name
				@fragments = []
			end

			def visit_call_node(node)
				case node
				in { name: :fragment, receiver: nil, arguments: { arguments: [Prism::StringNode | Prism::SymbolNode => argument] } } if argument.unescaped == @name
					@fragments << node
				else
					# no-op
				end

				super
			end
		end
	end
end
