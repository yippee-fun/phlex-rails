# frozen_string_literal: true

test "rendering a CSV without Active Record loaded" do
	script = <<~RUBY
		require "action_controller/railtie"
		require "phlex/rails"

		class Example < Phlex::CSV
			def escape_csv_injection? = true

			def row_template(name)
				column "name", name
			end
		end

		raise "Active Record is loaded" if defined?(ActiveRecord)
		print Example.new(["Joel"]).call
	RUBY

	output = IO.popen([RbConfig.ruby, "-e", script], err: [:child, :out], &:read)

	assert_equal output, "name\nJoel\n"
	assert_equal $?.exitstatus, 0
end
