# frozen_string_literal: true

module Phlex::Rails::Helpers::DatalistTag
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-datalist_tag)
	register_output_helper def datalist_tag(...) = nil
end
