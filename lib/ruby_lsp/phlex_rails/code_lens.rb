# frozen_string_literal: true

module RubyLsp
	module PhlexRails
		# Shows where a component is rendered, from `SomeComponent.new` calls in app/.
		class CodeLens
			include Requests::Support::Common

			def initialize(response_builder, index, render_sites, workspace_path, dispatcher)
				@response_builder = response_builder
				@index = index
				@render_sites = render_sites
				@workspace_path = workspace_path
				@nesting = []

				dispatcher.register(self, :on_class_node_enter, :on_class_node_leave, :on_module_node_enter, :on_module_node_leave)
			end

			def on_class_node_enter(node)
				@nesting << node.constant_path.slice

				class_name = @nesting.join("::")

				return unless component?(class_name)

				sites = @render_sites.for(class_name, @workspace_path)

				return if sites.empty?

				@response_builder << create_code_lens(
					node,
					title: (sites.one? ? "Rendered in #{sites.first.label}" : "Rendered in #{sites.length} places"),
					command_name: "rubyLsp.openFile",
					arguments: [sites.map { |site| "#{URI::Generic.from_path(path: site.path)}#L#{site.line}" }],
					data: { type: "file" },
				)
			end

			def on_class_node_leave(node)
				@nesting.pop
			end

			def on_module_node_enter(node)
				@nesting << node.constant_path.slice
			end

			def on_module_node_leave(node)
				@nesting.pop
			end

			private def component?(class_name)
				@index.linearized_ancestors_of(class_name).include?("Phlex::SGML")
			rescue RubyIndexer::Index::NonExistingNamespaceError
				false
			end
		end

		# The `SomeConstant.new` calls in each file under app/, cached until the file changes.
		class RenderSites
			Site = Data.define(:component, :owner, :path, :line, :label)

			def initialize(index)
				@index = index
				@files = {}
			end

			def for(class_name, workspace_path)
				Dir.glob("app/**/*.rb", base: workspace_path).sort.flat_map { |path| in_file(File.join(workspace_path, path)) }.select do |site|
					site.component == class_name && site.owner != class_name
				end
			end

			private def in_file(path)
				mtime = File.mtime(path)

				case @files[path]
				in [^mtime, sites]
					sites
				else
					RenderSiteFinder.find(Prism.parse_file(path).value, @index, path).tap do |sites|
						@files[path] = [mtime, sites]
					end
				end
			end
		end

		class RenderSiteFinder < Prism::Visitor
			def self.find(node, index, path)
				new(index, path).tap { |finder| node.accept(finder) }.sites
			end

			attr_reader :sites

			def initialize(index, path)
				@index = index
				@path = path
				@nesting = []
				@method_name = nil
				@sites = []
			end

			def visit_class_node(node)
				within(node.constant_path.slice) { super }
			end

			def visit_module_node(node)
				within(node.constant_path.slice) { super }
			end

			def visit_def_node(node)
				outer, @method_name = @method_name, node.name
				super
			ensure
				@method_name = outer
			end

			def visit_call_node(node)
				case node
				in { name: :new, receiver: Prism::ConstantReadNode | Prism::ConstantPathNode => receiver }
					if (component = @index.resolve(receiver.slice, @nesting)&.first&.name)
						owner = @nesting.join("::")

						@sites << RenderSites::Site.new(
							component:,
							owner:,
							path: @path,
							line: node.location.start_line,
							label: label(owner),
						)
					end
				else
					# no-op
				end

				super
			end

			private def within(name)
				@nesting << name
				yield
			ensure
				@nesting.pop
			end

			private def label(owner)
				case [owner, @method_name]
				in ["", nil] then File.basename(@path)
				in [_, nil] then owner
				in ["", Symbol] then "##{@method_name}"
				else "#{owner}##{@method_name}"
				end
			end
		end
	end
end
