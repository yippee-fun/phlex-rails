# frozen_string_literal: true

module Phlex::Rails::Helpers::TurboRefreshesWith
	# Turbo’s version calls `provide :head`, which a Phlex layout never yields, so we output the meta tags directly.
	# [Turbo Docs](https://rubydoc.info/github/hotwired/turbo-rails/Turbo%2FDriveHelper:turbo_refreshes_with)
	def turbo_refreshes_with(method: :replace, scroll: :reset)
		raw(view_context.turbo_refresh_method_tag(method))
		raw(view_context.turbo_refresh_scroll_tag(scroll))
		nil
	end
end
