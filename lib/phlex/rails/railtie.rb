# frozen_string_literal: true

class Phlex::Rails::Railtie < ::Rails::Railtie
	config.phlex = ActiveSupport::OrderedOptions.new
	config.phlex.compile = true
	config.phlex.on_compile_failure = Phlex::Compiler::DEFAULT_FAILURE_HANDLER

	rake_tasks do
		load "#{__dir__}/tasks.rake"
	end

	# After eager loading, so a production app's components are compiled
	# before the server forks. Components autoloaded later are compiled as
	# they load, and an unloaded one is forgotten once a reload finishes.
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
				Phlex::Compiler.precompile(value) if Class === value && Phlex::SGML > value
			end

			loader.on_unload do |_cpath, value, _abspath|
				unloaded << value if Class === value && Phlex::SGML > value
			end
		end

		app.reloader.after_class_unload do
			unloaded.each { |component| Phlex::Compiler.forget(component) }
			unloaded.clear
		end
	end
end
