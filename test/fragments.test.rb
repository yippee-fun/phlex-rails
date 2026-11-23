# frozen_string_literal: true

class FragmentsTest < Quickdraw::Test
	test "rendering with an X-Fragments header" do
		response = get("/posts", headers: { "X-Fragments" => "post_1" })

		assert_equal response.status, 200
		assert_equivalent_html response.body, <<~HTML.strip
			<div id="post_1">
				<h1>Post 1</h1>
				<p>This is the first post.</p>
			</div>
		HTML
	end
end
