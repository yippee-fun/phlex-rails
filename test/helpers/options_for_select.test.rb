# frozen_string_literal: true

test "options_for_select as a value for a select_tag" do
	component = Class.new(Phlex::HTML) do
		include Phlex::Rails::Helpers::SelectTag
		include Phlex::Rails::Helpers::OptionsForSelect

		define_method :view_template do
			select_tag :test, options_for_select([["Option 1", 1], ["Option 2", 2]])
		end
	end

	error = assert_raises Phlex::ArgumentError do
		render(component)
	end

	assert error.message.include?("options_for_select")
end

test "options_for_select as a value for a form_with select" do
	component = Class.new(Phlex::HTML) do
		include Phlex::Rails::Helpers::FormWith
		include Phlex::Rails::Helpers::OptionsForSelect

		define_method :view_template do
			form_with(url: "/") do |form|
				form.select(:test, options_for_select([["Option 1", 1], ["Option 2", 2]]))
			end
		end
	end

	controller.define_singleton_method(:form_authenticity_token) { |_| "(example form authenticity token)" }

	error = assert_raises Phlex::ArgumentError do
		render(component)
	end

	assert error.message.include?("options_for_select")
end

test "options_for_select in a form with select" do
	component = Class.new(Phlex::HTML) do
		include Phlex::Rails::Helpers::FormWith
		include Phlex::Rails::Helpers::OptionsForSelect

		define_method :view_template do
			form_with(url: "/") do |form|
				form.select(:test) do
					options_for_select([["Option 1", 1], ["Option 2", 2]])
				end
			end
		end
	end

	controller.define_singleton_method(:form_authenticity_token) { |_| "(example form authenticity token)" }

	output = render(component)

	assert_equivalent_html output, <<~HTML
		<form action="/" accept-charset="UTF-8" method="post">
			<input type="hidden" name="utf8" value="✓" autocomplete="off">
			<input type="hidden" name="authenticity_token" value="(example form authenticity token)" autocomplete="off">
			<select name="test">
				<option value="1">Option 1</option>
				<option value="2">Option 2</option>
			</select>
		</form>
	HTML
end

test "options_for_select in a select_tag" do
	component = Class.new(Phlex::HTML) do
		include Phlex::Rails::Helpers::SelectTag
		include Phlex::Rails::Helpers::OptionsForSelect

		define_method :view_template do
			select_tag :test do
				options_for_select([["Option 1", 1], ["Option 2", 2]])
			end
		end
	end

	output = render(component)

	assert_equivalent_html output, <<~HTML
		<select name="test" id="test">
			<option value="1">Option 1</option>
			<option value="2">Option 2</option>
		</select>
	HTML
end
