# frozen_string_literal: true

class RoutesTest < Quickdraw::Test
	test "generated _path helpers" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::Routes

			define_method :view_template do
				a(href: posts_path) { "Posts" }
			end
		end

		output = render component

		assert_equivalent_html output, <<~HTML.strip
			<a href="/posts">Posts</a>
		HTML
	end

	test "generated _url helpers" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::Routes

			define_method :view_template do
				a(href: posts_url) { "Posts" }
			end
		end

		output = render component

		assert_equivalent_html output, <<~HTML.strip
			<a href="http://test.host/posts">Posts</a>
		HTML
	end
end
