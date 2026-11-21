# frozen_string_literal: true

module Phlex::Rails::SGML::State
	def buffer
		@user_context[:capture_context]&.output_buffer&.raw_buffer || super
	end

	def capture(cache: false)
		capture_context = @user_context[:capture_context]
		return super unless capture_context

		original_capturing = @capturing
		original_fragments = @fragments
		original_should_render = @should_render
		original_cache_stack = cache ? cache_stack : @cache_stack
		captured_cache_stack = nil
		new_buffer = nil

		capture_context.capture do
			new_buffer = buffer
			@capturing = true
			@fragments = nil
			@should_render = true
			@cache_stack = nil unless cache
			yield
		ensure
			captured_cache_stack = @cache_stack unless cache
			@capturing = original_capturing
			@fragments = original_fragments
			@should_render = original_should_render
			@cache_stack = original_cache_stack
		end

		# Rails helpers escape captured output unless it's marked safe.
		captured = new_buffer.html_safe

		if captured_cache_stack && !(fragment_map = captured_cache_stack[0][1]).empty?
			captured.instance_variable_set(:@__phlex_fragments, [captured.dup.freeze, fragment_map])
		end

		captured
	end
end
