# frozen_string_literal: true

class DOMTargetTest < Quickdraw::Test
	# Added in Rails 8.1
	if ActionView::RecordIdentifier.method_defined?(:dom_target)
		test "returns the joined DOM target as a value" do
			component = Class.new(Phlex::HTML) do
				include Phlex::Rails::Helpers::DOMTarget

				define_method :view_template do
					div(id: dom_target(:post, :comments))
				end
			end

			assert_equal render(component), %(<div id="post_comments"></div>)
		end
	end
end
