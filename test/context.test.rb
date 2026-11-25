# frozen_string_literal: true

test "calling with a context that isn't a Hash" do
	component = Class.new(Phlex::HTML) do
		def view_template
			h1 { "Hello" }
		end
	end

	error = assert_raises(Phlex::ArgumentError) { component.new.call(context: Object.new) }
	assert_equal error.message, "Expected context to be a Hash, got Object."
end

test "calling with a Hash context" do
	component = Class.new(Phlex::HTML) do
		def view_template
			h1 { "Hello" }
		end
	end

	assert_equal component.new.call(context: {}), "<h1>Hello</h1>"
end
