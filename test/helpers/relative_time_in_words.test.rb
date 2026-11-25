# frozen_string_literal: true

class RelativeTimeInWordsTest < Quickdraw::Test
	# Added in Rails 8.1
	if ActionView::Helpers::DateHelper.method_defined?(:relative_time_in_words)
		test "returns the relative time as a value" do
			component = Class.new(Phlex::HTML) do
				include Phlex::Rails::Helpers::RelativeTimeInWords

				define_method :view_template do
					span { relative_time_in_words(3.minutes.ago) }
				end
			end

			assert_equal render(component), "<span>3 minutes ago</span>"
		end
	end
end
