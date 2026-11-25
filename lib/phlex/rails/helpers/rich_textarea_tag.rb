# frozen_string_literal: true

module Phlex::Rails::Helpers::RichTextAreaTag
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionText/TagHelper.html#method-i-rich_textarea_tag)
	register_output_helper def rich_textarea_tag(...) = nil

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionText/TagHelper.html#method-i-rich_text_area_tag)
	register_output_helper def rich_text_area_tag(...) = nil
end
