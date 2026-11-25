# frozen_string_literal: true

namespace :phlex do
	namespace :compiler do
		desc "List what the Phlex compiler leaves to the runtime in the app's components"
		task explain: :environment do
			Rails.application.eager_load!

			root = "#{Rails.root}/"

			compiled, uncompiled = Phlex::Compiler.loaded_components.partition(&:compile?)

			opted_out = uncompiled.filter_map do |component|
				next unless component.instance_variable_get(:@__phlex_compile__) == false

				path, line = Object.const_source_location(component.name)
				Phlex::Compiler::Diagnostics::Diagnostic.new(path:, line:, message: "#{component} says compile false, so it and its subclasses render uncompiled")
			end

			diagnostics = (opted_out + compiled.flat_map { |component| Phlex::Compiler.explain(component) })
				.select { |diagnostic| diagnostic.path&.start_with?(root) }
				.uniq
				.sort_by { |diagnostic| [diagnostic.path, diagnostic.line || 0] }

			if diagnostics.empty?
				puts "Every component compiles in full."
			else
				diagnostics.each { |diagnostic| puts diagnostic.to_s.delete_prefix(root) }
			end
		end

		desc "Show the Ruby the Phlex compiler generates for a component"
		task :source, [:component] => :environment do |_task, arguments|
			name = arguments[:component] or abort "Name a component, as in `rails phlex:compiler:source[Components::Card]`."
			component = name.constantize
			source = Phlex::Compiler.source(component)

			if source.empty?
				puts "#{component} has nothing to compile."
			else
				puts source.gsub(%r{^# #{Regexp.escape(Rails.root.to_s)}/}, "# ")
			end
		end
	end
end
