# frozen_string_literal: true

require "ruby_lsp/internal"
require "ruby_lsp/phlex_rails/addon"

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
