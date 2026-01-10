# frozen_string_literal: true

require_relative "lib/phlex/rails/version"

Gem::Specification.new do |spec|
	spec.name = "phlex-rails"
	spec.version = Phlex::Rails::VERSION
	spec.authors = ["Joel Drapper", "Will Cosgrove"]
	spec.email = ["joel@drapper.me"]

	spec.summary = "A Phlex adapter for Rails"
	spec.description = "Object-oriented views in pure Ruby."
	spec.homepage = "https://www.phlex.fun"
	spec.license = "MIT"
	spec.required_ruby_version = ">= 3.2"

	spec.metadata["homepage_uri"] = spec.homepage
	spec.metadata["source_code_uri"] = "https://github.com/phlex-ruby/phlex-rails"
	spec.metadata["changelog_uri"] = "https://github.com/phlex-ruby/phlex-rails/releases"
	spec.metadata["funding_uri"] = "https://github.com/sponsors/joeldrapper"
	spec.metadata["rubygems_mfa_required"] = "true"

	spec.files = Dir[
		"README.md",
		"LICENSE.txt",
		"lib/**/*"
	]

	spec.require_paths = ["lib"]

	spec.add_runtime_dependency "phlex", ">= 2.3.0", "< 3"
	spec.add_runtime_dependency "railties", ">= 7.1", "< 9"
	spec.add_runtime_dependency "zeitwerk", "~>2.7"
end
