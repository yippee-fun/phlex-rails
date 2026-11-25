# frozen_string_literal: true

module Phlex::Rails::Helpers::FieldSetTag
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-field_set_tag)
	register_output_helper def field_set_tag(...) = nil

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-fieldset_tag)
	register_output_helper def fieldset_tag(...) = nil
end
