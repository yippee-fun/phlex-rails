# frozen_string_literal: true

require "ruby_lsp/internal"
require "ruby_lsp/phlex_rails/addon"
require "ruby_lsp/test_helper"

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
