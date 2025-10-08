# frozen_string_literal: true

module Phlex::Generators
	class InstallGenerator < ::Rails::Generators::Base
		class_option :use_literal_gem, type: :boolean, default: true,
			desc: "include `extend Literal::Properties` in Components::Base (recommended)"
		source_root File.expand_path("templates", __dir__)

		def create_initializer
			template "phlex.rb.erb", File.join(destination_root, "config/initializers/phlex.rb")
		end

		def create_base_component
			template "base_component.rb.erb", File.join(destination_root, "app/components/base.rb")
		end

		def create_base_view
			template "base_view.rb.erb", File.join(destination_root, "app/views/base.rb")
		end
	end
end
