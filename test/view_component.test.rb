# frozen_string_literal: true

class ViewComponentTest < Quickdraw::Test
	test "rendering a view_component component from phlex" do
		component = Class.new(Phlex::HTML) do
			define_method :view_template do
				render BlogComponent.new(date: "Yesterday") do |blog|
					blog.with_header do
						plain "Hello"
						whitespace
						strong { "World" }
					end

					blog.with_post do
						p { "This is a post." }
					end
				end
			end
		end

		output = render component.new

		assert_equivalent_html output, <<~HTML
			<h1>
				Hello
				<strong>
					World
				</strong>
			</h1>
			<time>
				Yesterday
			</time>
			<section>
				<article>
					<p>
						This is a post.
				</article>
			</section>
		HTML
	end

	test "rendering a phlex component from view_component" do
		output = render NavComponent.new

		assert_equivalent_html output, <<~HTML
			<h1>Before</h1>
			<nav class="special-nav">
				<a class="special-nav-item" href="/">Home</a>
				<span class="special-nav-divider"></span>
				<a class="special-nav-item" href="/about">About</a>
			</nav>
			<h1>After</h1>
		HTML
	end
end
