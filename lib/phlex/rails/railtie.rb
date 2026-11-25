# frozen_string_literal: true

class Phlex::Rails::Railtie < ::Rails::Railtie
	config.phlex = ActiveSupport::OrderedOptions.new
	config.phlex.compile = true
	config.phlex.on_compile_failure = Phlex::Compiler::DEFAULT_FAILURE_HANDLER

	# The component a file defines and any nested in it, which Zeitwerk
	# doesn't report when they're defined in the same file. A constant naming
	# a class defined elsewhere isn't that class's file.
	NAME = Module.instance_method(:name)

	def self.components_in(cpath, value, components = [])
		return components unless Module === value && NAME.bind_call(value) == cpath

		components << value if Class === value && Phlex::SGML > value

		value.constants(false).each do |name|
			next if value.autoload?(name, false)

			components_in("#{cpath}::#{name}", value.const_get(name, false), components)
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
			loader.on_load do |cpath, value, _abspath|
				Phlex::Rails::Railtie.components_in(cpath, value).each { |component| Phlex::Compiler.precompile(component) }
			end

			loader.on_unload do |cpath, value, _abspath|
				unloaded.concat(Phlex::Rails::Railtie.components_in(cpath, value))
			end
		end

		app.reloader.after_class_unload do
			Phlex::Compiler.forget(*unloaded)
			unloaded.clear
		end
	end
end
