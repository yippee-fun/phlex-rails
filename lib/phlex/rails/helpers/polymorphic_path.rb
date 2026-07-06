# frozen_string_literal: true

module Phlex::Rails::Helpers
	module PolymorphicPath
		extend Phlex::Rails::HelperMacros

		# [Rails Docs](https://api.rubyonrails.org/classes/ActionDispatch/Routing/PolymorphicRoutes.html#method-i-polymorphic_path)
		register_value_helper def polymorphic_path(...) = nil
	end
end
