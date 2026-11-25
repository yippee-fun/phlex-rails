# frozen_string_literal: true

module Phlex
	module Rails
		module CSV
			def each_item(&)
				return super unless defined?(ActiveRecord::Relation) && ActiveRecord::Relation === collection
				return super unless collection.arel.orders.empty?

				collection.find_each(&)
			end
		end
	end
end
