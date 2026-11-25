# frozen_string_literal: true

module Phlex::Rails::Helpers::CSRFMetaTags
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/CsrfHelper.html#method-i-csrf_meta_tags)
	register_output_helper def csrf_meta_tags(...) = nil

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/CsrfHelper.html#method-i-csrf_meta_tag)
	register_output_helper def csrf_meta_tag(...) = nil
end
