# frozen_string_literal: true

class FieldSetTagTest < Quickdraw::Test
	test "fieldset_tag is an alias of field_set_tag" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::FieldSetTag

			define_method :view_template do
				field_set_tag("A") { "content" }
				fieldset_tag("A") { "content" }
			end
		end

		output = render(component)
		half = output.length / 2

		assert_equal output[0...half], output[half..]
		assert output.start_with?("<fieldset><legend>A</legend>content</fieldset>")
	end
end
