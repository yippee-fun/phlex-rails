# frozen_string_literal: true

module Phlex::Rails::SGML
	module ClassMethods
		def render_in(...)
			new.render_in(...)
		end
	end

	def method_missing(name, ...)
		super
	rescue NoMethodError => e
		if rendering? && view_context.respond_to?(name)
			const_name = name.to_s.gsub("?", "")

			module_name = Phlex::Rails::Helpers.constants.find do |mod|
				mod.name.underscore.gsub("domid", "dom_id") == const_name
			end

			# If we're missing a helper module, raise a NoMethodError with a helpful message,
			# otherwise re-raise the original error.
			if module_name
				raise NoMethodError.new(<<~MESSAGE)
					Try including `Phlex::Rails::Helpers::#{module_name}` in #{self.class.name}.
					```ruby
					include Phlex::Rails::Helpers::#{module_name}
					```
				MESSAGE
			else
				raise e
			end
		else
			raise e
		end
	end

	def partial(*, **, &block)
		if block
			Phlex::Rails::Partial.new(*, **) { capture(&block) }
		else
			Phlex::Rails::Partial.new(*, **)
		end
	end

	def helpers
		warn <<~MESSAGE
			The `helpers` method is deprecated and will be removed in the next
			minor version of phlex-rails.

			If you absolutely need to access the underlying Rails view context,
			you can do that via the `view_context` method, though this is
			not recommended.

			It is much safer to use one of the built-in helper adapters or to
			register your own adapter via `register_output_helper` or
			`register_value_helper`.

			See https://www.phlex.fun/rails/helpers
		MESSAGE

		view_context
	end

	def view_context
		if rendering?
			context[:rails_view_context]
		else
			raise Phlex::Rails::HelpersCalledBeforeRenderError.new(<<~MESSAGE)
				You can’t use Rails view helpers until after the component has started rendering.
			MESSAGE
		end
	end

	# If we’re rendered from view_component, we need to capture on the view_component context.
	def capture_context
		context[:capture_context]
	end

	def render(renderable = nil, &block)
		case renderable
		when Phlex::SGML, Proc, Method, String
			return super
		when Class
			return super if renderable < Phlex::SGML
		when Enumerable
			return super unless defined?(ActiveRecord::Relation) && ActiveRecord::Relation === renderable
		when nil
			return super
		end

		if renderable.respond_to?(:render_in) || renderable.respond_to?(:to_partial_path)
			if block
				raw capture_context.render(renderable) { |*a| capture(*a, &block) }
			else
				raw capture_context.render(renderable)
			end
		else
			super
		end
	end

	def low_level_cache(...)
		Rails.application.config.action_controller.perform_caching ? super : yield
	end

	def render_in(view_context, &erb)
		case view_context
		when defined?(ViewComponent::Base) && ViewComponent::Base
			rails_view_context = view_context.helpers
			capture_context = view_context
		else
			rails_view_context = view_context
			capture_context = view_context
		end

		context = {
			rails_view_context:,
			capture_context:,
		}

		fragments = if (request = context[:rails_view_context].request) && (fragment_header = request.headers["X-Fragments"])
			fragment_header.split(",").map(&:strip).presence
		end

		capture_context.capture do
			if erb
				call(context:, fragments:, &erb).html_safe
			else
				call(context:, fragments:).html_safe
			end
		end
	end

	def set_original_view_context(view_context)
		# no-op (see https://github.com/ViewComponent/view_component/issues/2207)
	end

	def enable_cache_reloading?
		Rails.env.development?
	end
end
