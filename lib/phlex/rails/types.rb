# frozen_string_literal: true

module Phlex
	module Rails
		module Types
			extend self

			def Buffered(type)
				-> (value) { Phlex::Rails::Buffered === value && type === value.unwrap }
			end

			def Builder(type)
				-> (value) { Phlex::Rails::Builder === value && type === value.unwrap }
			end
		end
	end
end
