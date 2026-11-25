# frozen_string_literal: true

test "render_in accepts options on a component" do
	component = Class.new(Phlex::HTML) do
		def view_template
			h1 { "Hello" }
		end
	end

	assert_equal component.new.render_in(view_context, locals: {}), "<h1>Hello</h1>"
	assert_equal component.render_in(view_context, locals: {}), "<h1>Hello</h1>"
end

test "render_in accepts options on a partial" do
	component = Class.new(Phlex::HTML) do
		define_method :view_template do
			render partial("hello")
		end
	end

	partial = component.new.partial("hello")
	assert_equivalent_html partial.render_in(view_context, locals: {}), "<h1>Hello</h1>"
end
