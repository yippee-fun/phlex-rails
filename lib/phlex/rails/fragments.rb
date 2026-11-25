# frozen_string_literal: true

class Phlex::Rails::Fragments
	def initialize(component, names)
		@component = component
		@names = names
	end

	def render_in(view_context, **, &)
		@component.render_in(view_context, fragments: @names, **, &)
	end
end
