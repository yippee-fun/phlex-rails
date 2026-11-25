# frozen_string_literal: true

class HelperMacrosTest < Quickdraw::Test
	test "register_output_helper with raw marked safe" do
		view_ctx = ActionController::Base.new.view_context
		view_ctx.define_singleton_method(:raw_html_producing_method) { "<span>ok</span>" }

		component = Class.new(Phlex::HTML) do
			register_output_helper :raw_html_producing_method, mark_safe: true

			def view_template
				div { raw_html_producing_method }
			end
		end

		assert_equivalent_html component.render_in(view_ctx), "<div><span>ok</span></div>"
	end

	test "register_output_helper with raw not marked safe (default)" do
		view_ctx = ActionController::Base.new.view_context
		view_ctx.define_singleton_method(:raw_html_producing_method) { "<span>ok</span>" }

		component = Class.new(Phlex::HTML) do
			register_output_helper :raw_html_producing_method

			def view_template
				div { raw_html_producing_method }
			end
		end

		error = assert_raises Phlex::ArgumentError do
			component.render_in(view_ctx)
		end
		assert_equal error.message, "You passed an unsafe object to `raw`."
	end
end
