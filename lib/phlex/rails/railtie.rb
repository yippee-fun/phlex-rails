# frozen_string_literal: true

class Phlex::Rails::Railtie < ::Rails::Railtie
	config.phlex = ActiveSupport::OrderedOptions.new
	config.phlex.compile = true
	config.phlex.on_compile_failure = Phlex::Compiler::DEFAULT_FAILURE_HANDLER

	# The component a file defines and any nested in it, which Zeitwerk
	# doesn't report when they're defined in the same file.
	def self.components_in(value, components = [])
		return components unless Module === value

		components << value if Class === value && Phlex::SGML > value

		value.constants(false).each do |name|
			next if value.autoload?(name, false)

			nested = value.const_get(name, false)
			components_in(nested, components) if Module === nested && nested.name == "#{value.name}::#{name}"
		end

		components
	end

	rake_tasks do
		load "#{__dir__}/tasks.rake"
	end

	# After eager loading, so a production app's components are compiled
	# before the server forks. Components autoloaded later are compiled as
	# they load, and the unloaded ones are forgotten once a reload finishes.
	config.after_initialize do |app|
		unless app.config.phlex.compile
			Phlex::Compiler.disable!
			next
		end

		on_failure = app.config.phlex.on_compile_failure
		Phlex::Compiler.enable!(on_failure:)
		Phlex::Compiler.loaded_components.each { |component| Phlex::Compiler.precompile(component) }

		unloaded = []

		Rails.autoloaders.each do |loader|
			loader.on_load do |_cpath, value, _abspath|
				Phlex::Rails::Railtie.components_in(value).each { |component| Phlex::Compiler.precompile(component) }
			end

			loader.on_unload do |_cpath, value, _abspath|
				unloaded.concat(Phlex::Rails::Railtie.components_in(value))
			end
		end

		app.reloader.after_class_unload do
			Phlex::Compiler.forget(*unloaded)
			unloaded.clear
		end
	end
end
