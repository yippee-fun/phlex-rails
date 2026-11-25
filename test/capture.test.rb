# frozen_string_literal: true

class CaptureTest < Quickdraw::Test
	class Component < Phlex::HTML
		def view_template
			yield if block_given?
		end
	end

	UNSET = Object.new.freeze

	test "capturing nothing returns an empty string" do
		output = UNSET
		view_context = ActionController::Base.new.view_context

		Component.render_in(view_context) do |c|
			output = c.capture do
				# Intentionally empty to capture nothing
			end
		end

		assert_equal "", output
	end
end
