# frozen_string_literal: true

require "bootsnap/setup"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"

require "phlex/rails"
require "view_component"

class App < Rails::Application
	config.eager_load = false
	config.hosts.clear
	config.autoload_paths << "#{root}/app/view_components"
	config.secret_key_base = "secret-key"
	config.action_dispatch.show_exceptions = :rescuable

	config.action_controller.perform_caching = true

	# Components compile, and one that would fall back to rendering uncompiled
	# raises instead. PHLEX_COMPILER=false runs the suite uncompiled.
	config.phlex.compile = ENV["PHLEX_COMPILER"] != "false"
	config.phlex.on_compile_failure = -> (component, error) { raise error }

	routes.append do
		resources :posts
	end
end

class PostsController < ActionController::Base
	def index
		render Views::Posts::Index.new
	end
end

App.initialize!

class Quickdraw::Test
	def render(...)
		view_context.render(...)
	end

	def view_context
		controller.view_context
	end

	def controller
		@controller ||= ActionView::TestCase::TestController.new
	end

	def get(url, headers:)
		response = Rack::MockRequest.new(Rails.application).get(
			url,
			**headers.transform_keys { |key| "HTTP_#{key.to_s.upcase.tr('-', '_')}" }
		)
	end
end

Zeitwerk::Loader.eager_load_all
