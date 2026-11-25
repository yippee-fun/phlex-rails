# frozen_string_literal: true

require "active_record"

class CollectionPost
	def initialize(title)
		@title = title
	end

	attr_reader :title

	def to_partial_path
		"posts/post"
	end
end

class CollectionRecord < ActiveRecord::Base
	self.table_name = "posts"
end

class CollectionsTest < Quickdraw::Test
	test "rendering an ActiveRecord::Relation uses Rails collection rendering" do
		relation = relation_of(CollectionPost.new("First"), CollectionPost.new("Second"))

		example = Class.new(Phlex::HTML) do
			define_method :view_template do
				ul { render relation }
			end
		end

		assert_equivalent_html render(example.new), <<~HTML.strip
			<ul>
				<li>First 0</li>
				<li>Second 1</li>
			</ul>
		HTML
	end

	test "rendering an empty ActiveRecord::Relation renders nothing" do
		relation = relation_of

		example = Class.new(Phlex::HTML) do
			define_method :view_template do
				ul { render relation }
			end
		end

		assert_equivalent_html render(example.new), "<ul></ul>"
	end

	test "rendering an Array of components still renders each one" do
		item = Class.new(Phlex::HTML) do
			def initialize(title)
				@title = title
			end

			def view_template
				li { @title }
			end
		end

		example = Class.new(Phlex::HTML) do
			define_method :view_template do
				ul { render [item.new("First"), item.new("Second")] }
			end
		end

		assert_equivalent_html render(example.new), <<~HTML.strip
			<ul>
				<li>First</li>
				<li>Second</li>
			</ul>
		HTML
	end

	private def relation_of(*records)
		CollectionRecord.all.tap { |relation| relation.__send__(:load_records, records) }
	end
end
