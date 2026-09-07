# frozen_string_literal: true

module Phlex::Rails::Helpers::RelativeTimeInWords
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-relative_time_in_words)
	register_value_helper def relative_time_in_words(...) = nil
end
