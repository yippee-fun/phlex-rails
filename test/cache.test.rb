# frozen_string_literal: true

class CacheTest < Quickdraw::Test
	test "basic caching test" do
		assert_equivalent_html render(Components::Cache.new("Original")), <<~HTML.strip
			<h1>Original</h1>
		HTML

		assert_equivalent_html render(Components::Cache.new("Something else")), <<~HTML.strip
			<h1>Original</h1>
		HTML
	end
end
