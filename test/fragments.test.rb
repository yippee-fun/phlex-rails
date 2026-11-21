# frozen_string_literal: true

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

test "an X-Fragments header that names no fragments renders the whole page" do
	full_page = get("/posts", headers: {}).body
	assert_includes full_page, %(<div id="post_2">)

	[" , ", ",", " "].each do |header|
		response = get("/posts", headers: { "X-Fragments" => header })

		assert_equal response.status, 200
		assert_equal response.body, full_page
	end
end

test "an X-Fragments header ignores empty fragment names" do
	response = get("/posts", headers: { "X-Fragments" => " , post_1, " })

	assert_equivalent_html response.body, <<~HTML.strip
		<div id="post_1">
			<h1>Post 1</h1>
			<p>This is the first post.</p>
		</div>
	HTML
end
