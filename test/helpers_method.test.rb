# frozen_string_literal: true

class HelpersMethodTest < Quickdraw::Test
	test "helpers raises with guidance" do
		component = Class.new(Phlex::HTML) do
			define_method :view_template do
				helpers.link_to("/") { "Home" }
			end
		end

		error = assert_raises(NoMethodError) do
			render component
		end

		assert error.message.start_with?("The `helpers` method was removed in phlex-rails 3.")
	end
end
