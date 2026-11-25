# frozen_string_literal: true

class Components::NestedTable::RowContainer < Phlex::HTML
	attr_accessor :tag

	def initialize(tag: "tbody")
		@tag = tag
		@rows = []
	end

	def with_row(&)
		@rows << Components::NestedTable::Row.with_content(&)
	end

	def before_template(&)
		capture(&)
		super
	end

	def view_template
		case @tag
		when "thead"
			thead { render @rows }
		when "tbody"
			tbody { render @rows }
		when "tfoot"
			tfoot { render @rows }
		end
	end
end
