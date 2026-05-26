# frozen_string_literal: true

class Phlex::Rails::Partial
	def initialize(path, *args, **kwargs, &block)
		@path = path
		@args = args
		@kwargs = kwargs
		@block = block
	end

	def render_in(view_context, **options, &block)
		block ||= @block
		view_context.render(@path, *@args, **@kwargs, &block)
	end
end
