# frozen_string_literal: true

require "active_model"

class PolymorphicRoutesTest < Quickdraw::Test
	Post = Struct.new(:id) do
		extend ActiveModel::Naming
		include ActiveModel::Conversion

		def self.name = "Post"
		def persisted? = true
	end

	test "polymorphic_path" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::PolymorphicPath

			define_method :view_template do
				a(href: polymorphic_path(Post.new(1))) { "Post" }
			end
		end

		assert_equal render(component), %(<a href="/posts/1">Post</a>)
	end

	test "polymorphic_url" do
		component = Class.new(Phlex::HTML) do
			include Phlex::Rails::Helpers::PolymorphicURL

			define_method :view_template do
				a(href: polymorphic_url(Post.new(1))) { "Post" }
			end
		end

		assert_equal render(component), %(<a href="http://test.host/posts/1">Post</a>)
	end
end
