# frozen_string_literal: true

require "ruby_lsp/internal"
require "ruby_lsp/phlex_rails/addon"
require "ruby_lsp/test_helper"
require "tmpdir"

class RubyLspIndexingTest < Quickdraw::Test
	test "indexes registered helpers" do
		index = RubyIndexer::Index.new
		index.index_single(URI::Generic.from_path(path: "/fake.rb"), <<~RUBY)
			module Helpers
				register_output_helper :output_helper
				register_value_helper :value_helper
				register_builder_yielding_helper :builder_helper
			end
		RUBY

		assert_equal index.resolve_method("output_helper", "Helpers")&.length, 1
		assert_equal index.resolve_method("value_helper", "Helpers")&.length, 1
		assert_equal index.resolve_method("builder_helper", "Helpers")&.length, 1
	end
end

class RubyLspDefinitionTest < Quickdraw::Test
	include RubyLsp::TestHelper

	SOURCE = <<~RUBY
		class PostsController < ActionController::Base
			def index
				render Views::Posts::Index.new.fragments(:post_1, "post_2", :missing)
			end
		end

		class Views::Posts::Show < Phlex::HTML
			def view_template
				render partial("card")
				render partial("missing")
			end
		end
	RUBY

	POSTS_INDEX = File.expand_path("../app/views/posts/index.rb", __dir__)

	test "goes from a symbol fragment name to the fragment" do
		assert_equal definitions(2, 47), [[POSTS_INDEX, 7]]
	end

	test "goes from a string fragment name to the fragment" do
		assert_equal definitions(2, 57), [[POSTS_INDEX, 13]]
	end

	test "ignores fragment names that aren't defined" do
		assert_equal definitions(2, 66), []
	end

	test "goes from a partial to its file" do
		assert_equal definitions(8, 20), [[File.expand_path("../app/views/_card.html.erb", __dir__), 0]]
	end

	test "ignores partials that don't exist" do
		assert_equal definitions(9, 20), []
	end

	private def definitions(line, character)
		with_server(SOURCE) do |server, uri|
			server.global_state.index.index_single(URI::Generic.from_path(path: POSTS_INDEX), File.read(POSTS_INDEX))
			server.process_message(id: 1, method: "textDocument/definition", params: { textDocument: { uri: }, position: { line:, character: } })

			Array(pop_result(server).response).map { |link| [URI(link.target_uri).path, link.target_range.start.line] }
		end
	end
end

class RubyLspCodeLensTest < Quickdraw::Test
	include RubyLsp::TestHelper

	COMPONENT = <<~RUBY
		module Views
			module Posts
				class Show < Phlex::HTML
					def view_template
						render Show.new
					end
				end
			end
		end

		class NotAComponent
		end
	RUBY

	CONTROLLER = <<~RUBY
		class PostsController < ActionController::Base
			def show
				render Views::Posts::Show.new
			end

			def edit
				Views::Posts::Show
			end
		end
	RUBY

	LAYOUT = <<~RUBY
		module Views
			class Layout < Phlex::HTML
				def view_template
					render Posts::Show.new
				end
			end
		end
	RUBY

	test "shows where a component is rendered" do
		lenses = code_lenses({ "app/controllers/posts_controller.rb" => CONTROLLER, "app/views/layout.rb" => LAYOUT })

		assert_equal lenses.map { |lens| [lens.range.start.line, lens.command.title] }, [[2, "Rendered in 2 places"]]
		assert_equal lenses.first.command.arguments.first.map { |uri| uri[%r{app/.*}] }, ["app/controllers/posts_controller.rb#L3", "app/views/layout.rb#L4"]
	end

	test "names the place when a component is rendered in one place" do
		lenses = code_lenses({ "app/controllers/posts_controller.rb" => CONTROLLER })

		assert_equal lenses.map { |lens| lens.command.title }, ["Rendered in PostsController#show"]
	end

	test "shows nothing for a component that isn't rendered" do
		assert_equal code_lenses({}), []
	end

	private def code_lenses(files)
		Dir.mktmpdir do |workspace|
			files.merge("app/views/posts/show.rb" => COMPONENT).each do |path, source|
				FileUtils.mkdir_p(File.dirname(File.join(workspace, path)))
				File.write(File.join(workspace, path), source)
			end

			uri = URI::Generic.from_path(path: File.join(workspace, "app/views/posts/show.rb"))

			with_server(COMPONENT, uri) do |server, uri|
				server.global_state.instance_variable_set(:@workspace_uri, URI::Generic.from_path(path: workspace))
				index = server.global_state.index
				index.index_single(URI::Generic.from_path(path: "/phlex/html.rb"), "module Phlex; class SGML; end; class HTML < SGML; end; end")
				files.each { |path, source| index.index_single(URI::Generic.from_path(path: File.join(workspace, path)), source) }

				server.process_message(id: 1, method: "textDocument/codeLens", params: { textDocument: { uri: } })

				pop_result(server).response.select { |lens| lens.command.command == "rubyLsp.openFile" }
			end
		end
	end
end

class RubyLspHelperAdapterTest < Quickdraw::Test
	include RubyLsp::TestHelper

	SOURCE = <<~RUBY
		class Base < Phlex::HTML
			include Phlex::Rails::Helpers::ButtonTo
		end

		class Card < Base
			def view_template
				link_t
				button_t
				link_to
			end
		end

		class NotAComponent
			def call
				link_t
			end
		end
	RUBY

	test "completes a helper whose adapter isn't included, and includes it" do
		item = completions(6, 8).find { |item| item.label == "link_to" }

		assert_equal item.label_details.description, "include Phlex::Rails::Helpers::LinkTo"
		assert_equal item.additional_text_edits.map { |edit| [edit.range.start.line, edit.new_text] }, [[5, "\tinclude Phlex::Rails::Helpers::LinkTo\n"]]
	end

	test "leaves helpers whose adapter an ancestor includes to ruby-lsp" do
		assert_equal completions(7, 10).select { |item| item.label_details&.description&.start_with?("include") }, []
	end

	test "doesn't complete helpers outside components" do
		assert_equal completions(14, 8).select { |item| item.label == "link_to" }, []
	end

	test "explains how to include a missing helper on hover" do
		assert_equal hover(8, 3).contents.value.include?("include Phlex::Rails::Helpers::LinkTo"), true
	end

	private def completions(line, character)
		request("textDocument/completion", line, character)
	end

	private def hover(line, character)
		request("textDocument/hover", line, character)
	end

	private def request(method, line, character)
		with_server(SOURCE) do |server, uri|
			index = server.global_state.index
			index.index_single(URI::Generic.from_path(path: "/phlex/html.rb"), "module Phlex; class SGML; end; class HTML < SGML; end; end")

			%w[link_to button_to].each do |helper|
				path = File.expand_path("../lib/phlex/rails/helpers/#{helper}.rb", __dir__)
				index.index_single(URI::Generic.from_path(path:), File.read(path))
			end

			server.process_message(id: 1, method:, params: { textDocument: { uri: }, position: { line:, character: } })
			pop_result(server).response
		end
	end
end

class RubyLspExplainTest < Quickdraw::Test
	include RubyLsp::TestHelper

	test "the server add-on explains a component" do
		component = Class.new(Phlex::HTML)
		stub_const = "RubyLspExplainCase#{object_id}"
		Object.const_set(stub_const, component)

		original = Phlex::Compiler.method(:explain)
		Phlex::Compiler.define_singleton_method(:explain) do |given|
			[Phlex::Compiler::Diagnostics::Diagnostic.new(path: "/app/views/card.rb", line: 3, message: "div keeps its call because reasons")] if given == component
		end

		assert_equal server_addon_result("explain", class_name: stub_const), {
			"diagnostics" => [{ "path" => "/app/views/card.rb", "line" => 3, "message" => "div keeps its call because reasons" }],
		}
	ensure
		Phlex::Compiler.singleton_class.define_method(:explain, original) if original
		Object.__send__(:remove_const, stub_const) if stub_const && Object.const_defined?(stub_const)
	end

	test "the server add-on explains nothing for a class that isn't a component" do
		assert_equal server_addon_result("explain", class_name: "String"), { "diagnostics" => [] }
		assert_equal server_addon_result("explain", class_name: "NotAConstant"), { "diagnostics" => [] }
	end

	test "shows explain diagnostics as code lenses on their lines" do
		client = Object.new
		client.define_singleton_method(:delegate_request) do |server_addon_name:, request_name:, class_name:|
			next unless [server_addon_name, request_name, class_name] == ["PhlexRails", "explain", "Card"]

			{
				diagnostics: [
					{ path: "/views/card.rb", line: 3, message: "div keeps its call because reasons" },
					{ path: "/views/base.rb", line: 9, message: "elsewhere" },
					{ path: "/views/card.rb", line: nil, message: "compiling Card raised" },
				],
			}
		end

		source = "class Card < Phlex::HTML\n\tdef view_template\n\t\tdiv { }\n\tend\nend\n"
		uri = URI::Generic.from_path(path: "/views/card.rb")

		lenses = with_server(source, uri) do |server, uri|
			server.global_state.index.index_single(URI::Generic.from_path(path: "/phlex/html.rb"), "module Phlex; class SGML; end; class HTML < SGML; end; end")
			RubyLsp::Addon.get("PhlexRails", "0.1.0").instance_variable_set(:@rails_runner_client, client)
			server.process_message(id: 1, method: "textDocument/codeLens", params: { textDocument: { uri: } })
			pop_result(server).response.select { |lens| lens.command.title.start_with?("Phlex compiler") }
		end

		assert_equal lenses.map { |lens| [lens.range.start.line, lens.command.title] }, [
			[2, "Phlex compiler: div keeps its call because reasons"],
			[0, "Phlex compiler: compiling Card raised"],
		]
	end

	test "the server add-on writes a component's compiled source to a file" do
		component = Class.new(Phlex::HTML)
		stub_const = "RubyLspSourceCase#{object_id}"
		Object.const_set(stub_const, component)

		Phlex::Compiler.singleton_class.alias_method(:__original_source__, :source) if Phlex::Compiler.respond_to?(:source)
		Phlex::Compiler.define_singleton_method(:source) { |given| (given == component) ? "# /app/views/card.rb\ndef view_template; end\n" : "" }

		result = server_addon_result("source", class_name: stub_const)

		assert_equal result["path"], Rails.root.join("tmp/phlex/compiled/#{stub_const.underscore}.rb").to_s
		assert_equal File.read(result["path"]), "# /app/views/card.rb\ndef view_template; end\n"
	ensure
		if Phlex::Compiler.respond_to?(:__original_source__)
			Phlex::Compiler.singleton_class.alias_method(:source, :__original_source__)
			Phlex::Compiler.singleton_class.remove_method(:__original_source__)
		else
			Phlex::Compiler.singleton_class.remove_method(:source)
		end

		Object.__send__(:remove_const, stub_const) if Object.const_defined?(stub_const)
		FileUtils.rm_f(result["path"]) if result
	end

	test "the server add-on writes nothing when nothing compiles" do
		assert_equal server_addon_result("source", class_name: "String"), { "path" => nil }
	end

	test "shows a code lens that opens the compiled source" do
		client = Object.new
		client.define_singleton_method(:delegate_request) do |server_addon_name:, request_name:, class_name:|
			case [server_addon_name, request_name, class_name]
			in ["PhlexRails", "source", "Card"] then { path: "/app/tmp/phlex/compiled/card.rb" }
			in ["PhlexRails", "explain", _] then { diagnostics: [] }
			end
		end

		source = "class Card < Phlex::HTML\n\tdef view_template\n\t\tdiv { }\n\tend\nend\n"
		uri = URI::Generic.from_path(path: "/views/card.rb")

		lenses = with_server(source, uri) do |server, uri|
			server.global_state.index.index_single(URI::Generic.from_path(path: "/phlex/html.rb"), "module Phlex; class SGML; end; class HTML < SGML; end; end")
			RubyLsp::Addon.get("PhlexRails", "0.1.0").instance_variable_set(:@rails_runner_client, client)
			server.process_message(id: 1, method: "textDocument/codeLens", params: { textDocument: { uri: } })
			pop_result(server).response.select { |lens| lens.command.title == "Show compiled source" }
		end

		assert_equal lenses.map { |lens| [lens.range.start.line, lens.command.arguments] }, [[0, [["file:///app/tmp/phlex/compiled/card.rb"]]]]
	end

	private def server_addon_result(request, **params)
		require "ruby_lsp/ruby_lsp_rails/server"
		require "ruby_lsp/phlex_rails/server_addon"

		stdout = StringIO.new
		RubyLsp::PhlexRails::ServerAddon.new(stdout, StringIO.new, {}).execute(request, params)
		JSON.parse(stdout.string.split("\r\n\r\n", 2).last)["result"]
	end
end
