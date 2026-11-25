# frozen_string_literal: true

module RubyLsp
	module PhlexRails
		# Runs in ruby-lsp-rails' runner process, where the app is loaded, to
		# explain what the compiler leaves to the runtime and show what it generates.
		class ServerAddon < ::RubyLsp::Rails::ServerAddon
			def name
				"PhlexRails"
			end

			def execute(request, params)
				case request
				in "explain"
					send_result({ diagnostics: explain(params[:class_name]) })
				in "source"
					send_result({ path: write_source(params[:class_name]) })
				else
					send_error_response("Unknown PhlexRails request: #{request}")
				end
			end

			private def explain(class_name)
				component = component(class_name)

				return [] unless component && ::Phlex::Compiler.respond_to?(:explain)

				if component.respond_to?(:compile?) && !component.compile?
					path, line = Object.const_source_location(component.name)
					return [{ path:, line:, message: "#{component.name} says compile false" }]
				end

				::Phlex::Compiler.explain(component).map do |diagnostic|
					{ path: diagnostic.path, line: diagnostic.line, message: diagnostic.message }
				end
			rescue => e
				failed("explain", e)
				[]
			end

			# Written under tmp/ so the editor can open it like any other file.
			private def write_source(class_name)
				component = component(class_name)

				return unless component && ::Phlex::Compiler.respond_to?(:source)

				source = ::Phlex::Compiler.source(component)

				return if source.empty?

				path = ::Rails.root.join("tmp/phlex/compiled", "#{component.name.underscore}.rb")
				FileUtils.mkdir_p(path.dirname)
				File.write(path, source) unless File.file?(path) && File.read(path) == source
				path.to_s
			rescue ::Phlex::Compiler::Error
				nil
			rescue => e
				failed("source", e)
				nil
			end

			private def component(class_name)
				component = ActiveSupport::Inflector.safe_constantize(class_name.to_s)
				component if Class === component && component < ::Phlex::SGML
			end

			private def failed(request, error)
				log_message("PhlexRails #{request} failed: #{error.class}: #{error.message}", type: 1)
			end
		end
	end
end
