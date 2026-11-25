# frozen_string_literal: true

module Phlex::Rails::Helpers::DOMTarget
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_target)
	register_value_helper def dom_target(...) = nil
end
