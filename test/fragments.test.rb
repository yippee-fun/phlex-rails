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

	test "rendering fragments as a renderable" do
		assert_equivalent_html render(Views::Posts::Index.new.fragments("post_2")), <<~HTML.strip
			<div id="post_2">
				<h1>Post 2</h1>
				<p>This is the second post.</p>
			</div>
		HTML
	end

	test "rendering several fragments as a renderable" do
		assert_equivalent_html render(Views::Posts::Index.new.fragments(:post_1, "post_2")), <<~HTML.strip
			<div id="post_1">
				<h1>Post 1</h1>
				<p>This is the first post.</p>
			</div>
			<div id="post_2">
				<h1>Post 2</h1>
				<p>This is the second post.</p>
			</div>
		HTML
	end

	test "rendering fragments from inside a component" do
		component = Class.new(Phlex::HTML) do
			define_method :view_template do
				main { render Views::Posts::Index.new.fragments("post_1") }
			end
		end

		assert_equivalent_html render(component), <<~HTML.strip
			<main>
				<div id="post_1">
					<h1>Post 1</h1>
					<p>This is the first post.</p>
				</div>
			</main>
		HTML
	end

	test "fragments requires at least one name" do
		assert_raises(Phlex::ArgumentError) do
			Views::Posts::Index.new.fragments
		end
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
end
