# frozen_string_literal: true

class BufferedTest < Quickdraw::Test
	test "is clear about type" do
		buffered = Phlex::Rails::Buffered.new(nil, component: nil)
		assert_equal buffered.class, Phlex::Rails::Buffered
		assert buffered.is_a?(Phlex::Rails::Buffered)
	end

	test "can unwrap object" do
		object = Object.new
		buffered = Phlex::Rails::Buffered.new(object, component: nil)
		assert_equal object, buffered.unwrap
	end

	test "is clear when inspected" do
		buffered = Phlex::Rails::Buffered.new(nil, component: nil)
		assert_equal buffered.inspect, "Phlex::Rails::Buffered(nil)"
	end
end
