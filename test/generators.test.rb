# frozen_string_literal: true

require "rails/generators"
require "generators/phlex/view/view_generator"
require "generators/phlex/install/install_generator"
require "generators/phlex/component/component_generator"

class GeneratorsTest < Quickdraw::Test
	test "install generator" do
		path = tmpdir
		generator = Phlex::Generators::InstallGenerator.new
		generator.destination_root = path
		generator.invoke_all

		assert File.exist?("#{path}/config/initializers/phlex.rb")
		assert File.exist?("#{path}/app/components/base.rb")
		assert File.exist?("#{path}/app/views/base.rb")
		assert File.read("#{path}/app/components/base.rb").include?("def cache_store = Rails.cache")
	end

	test "view generator" do
		path = tmpdir
		generator = Phlex::Generators::ViewGenerator.new(["Articles::Index"])
		generator.destination_root = path
		generator.invoke_all

		assert File.exist?("#{path}/app/views/articles/index.rb")
	end

	test "component generator" do
		path = tmpdir
		generator = Phlex::Generators::ComponentGenerator.new(["Card"])
		generator.destination_root = path
		generator.invoke_all

		assert File.exist?("#{path}/app/components/card.rb")
	end
end
