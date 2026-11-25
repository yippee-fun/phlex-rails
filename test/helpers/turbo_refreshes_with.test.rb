# frozen_string_literal: true

class TurboRefreshesWithTest < Quickdraw::Test
	test "outputs the refresh meta tags directly" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::TurboRefreshesWith

			define_method :view_template do
				head { turbo_refreshes_with(method: :morph, scroll: :preserve) }
			end
		end

		context = view_context
		context.define_singleton_method(:turbo_refresh_method_tag) { |method| tag.meta(name: "turbo-refresh-method", content: method) }
		context.define_singleton_method(:turbo_refresh_scroll_tag) { |scroll| tag.meta(name: "turbo-refresh-scroll", content: scroll) }

		assert_equal context.render(component), %(<head><meta name="turbo-refresh-method" content="morph"><meta name="turbo-refresh-scroll" content="preserve"></head>)
	end
end
