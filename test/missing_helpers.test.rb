# frozen_string_literal: true

test "missing helpers" do
	component = Class.new(Phlex::HTML) do
		define_singleton_method(:name) { "Components::Post" }

		define_method :view_template do
			link_to("/posts") { "Posts" }
		end
	end

	error = assert_raises(NoMethodError) do
		render component
	end

	assert_equal error.message, <<~MESSAGE
		Try including `Phlex::Rails::Helpers::LinkTo` in Components::Post.
		```ruby
		include Phlex::Rails::Helpers::LinkTo
		```
	MESSAGE
end
