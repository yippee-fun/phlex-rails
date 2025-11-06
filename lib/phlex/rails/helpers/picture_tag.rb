# frozen_string_literal: true

module Phlex::Rails::Helpers::PictureTag
	extend Phlex::Rails::HelperMacros

	# [Rails Docs](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html#method-i-picture_tag)
	register_output_helper def picture_tag(...) = nil
end
