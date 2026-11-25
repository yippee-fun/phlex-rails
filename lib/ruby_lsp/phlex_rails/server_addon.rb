# frozen_string_literal: true

module RubyLsp
	module PhlexRails
		# Runs in ruby-lsp-rails' runner process, where the app is loaded, to
		# explain what the compiler leaves to the runtime.
		class ServerAddon < ::RubyLsp::Rails::ServerAddon
			def name
				"PhlexRails"
			end

			def execute(request, params)
				case request
				in "explain"
					send_result({ diagnostics: explain(params[:class_name]) })
				else
					send_error_response("Unknown PhlexRails request: #{request}")
				end
			rescue => e
				log_message("PhlexRails #{request} failed: #{e.class}: #{e.message}", type: 1)
				send_result({ diagnostics: [] })
			end

			private def explain(class_name)
				component = ActiveSupport::Inflector.safe_constantize(class_name.to_s)

				return [] unless Class === component && component < ::Phlex::SGML
				return [] unless ::Phlex::Compiler.respond_to?(:explain)

				if component.respond_to?(:compile?) && !component.compile?
					path, line = Object.const_source_location(component.name)
					return [{ path:, line:, message: "#{component.name} says compile false" }]
				end

				::Phlex::Compiler.explain(component).map do |diagnostic|
					{ path: diagnostic.path, line: diagnostic.line, message: diagnostic.message }
				end
			end
		end
	end
end
