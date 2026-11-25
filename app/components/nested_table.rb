# frozen_string_literal: true

class Components::NestedTable < Phlex::HTML
	def with_head(&)
		@head = Components::NestedTable::RowContainer.with_content(tag: "thead", &)
	end

	def with_body(&)
		@bodies << Components::NestedTable::RowContainer.with_content(tag: "tbody", &)
	end

	def with_foot(&)
		@foot = Components::NestedTable::RowContainer.with_content(tag: "tfoot", &)
	end

	def initialize
		@head = nil
		@bodies = []
		@foot = nil
	end

	def before_template(&)
		capture(&)
		super
	end

	def view_template(&)
		div do
			table(border: 2) do
				render @head if @head
				render @bodies
				render @foot if @foot
			end
		end
	end
end
