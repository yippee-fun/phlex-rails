# frozen_string_literal: true

class BuilderTest < Quickdraw::Test
	test "is clear about type" do
		builder = Phlex::Rails::Builder.new(nil, component: nil)
		assert_equal builder.class, Phlex::Rails::Builder
		assert builder.is_a?(Phlex::Rails::Builder)
	end

	test "can unwrap object" do
		object = Object.new
		builder = Phlex::Rails::Builder.new(object, component: nil)
		assert_equal object, builder.unwrap
	end

	test "is clear when inspected" do
		buffered = Phlex::Rails::Builder.new(nil, component: nil)
		assert_equal buffered.inspect, "Phlex::Rails::Builder(nil)"
	end
end
