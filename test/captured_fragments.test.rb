# frozen_string_literal: true

class CapturedFragmentsTest < Quickdraw::Test
	class View < Phlex::HTML
		def initialize(cache_store)
			@cache_store = cache_store
		end

		attr_reader :cache_store

		def view_template
			low_level_cache("page") do
				captured = capture do
					plain "é"
					fragment("piece") { span { "hello" } }
				end
				plain "前"
				raw safe(captured)
			end
		end
	end

	test "captured fragments have offsets at their insertion point on cache misses and hits" do
		store = ActiveSupport::Cache::MemoryStore.new

		assert_equal render(View.new(store)), "前é<span>hello</span>"

		controller.request.headers["X-Fragments"] = "piece"

		assert_equal render(View.new(store)), "<span>hello</span>"
		assert_equal render(View.new(ActiveSupport::Cache::MemoryStore.new)), "<span>hello</span>"
	end
end
