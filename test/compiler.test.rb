# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"

# Each test boots a Rails app of its own in a subprocess, since compiling,
# eager loading and reloading change global state.
class CompilerTest < Quickdraw::Test
	CARD = <<~RUBY
		# frozen_string_literal: true

		class Card < Phlex::HTML
			def view_template = div { "card" }
		end
	RUBY

	def with_app(env: "production", config: "", files: { "app/components/card.rb" => CARD })
		Dir.mktmpdir do |root|
			{
				"config/application.rb" => <<~RUBY,
					# frozen_string_literal: true

					require "rails"
					require "action_controller/railtie"
					require "phlex/rails"
					require "json"

					FAILURES = []

					def compiled_method?(component, name)
						Phlex.__compiled_source_maps__.key?(component.instance_method(name).source_location[0])
					end

					class App < Rails::Application
						config.root = #{root.inspect}
						config.eager_load = #{env == 'production'}
						config.enable_reloading = #{env == 'development'}
						config.logger = Logger.new(nil)
						config.secret_key_base = "secret"
						#{config}
					end
				RUBY
				"config/environment.rb" => <<~RUBY,
					# frozen_string_literal: true

					require_relative "application"

					App.initialize!
				RUBY
				"Rakefile" => <<~RUBY,
					# frozen_string_literal: true

					require_relative "config/application"

					Rails.application.load_tasks
				RUBY
				**files,
			}.each do |path, source|
				path = File.join(root, path)
				FileUtils.mkdir_p(File.dirname(path))
				File.write(path, source)
			end

			yield root
		end
	end

	def run_in(root, *command)
		output, error, status = Open3.capture3({ "RAILS_ENV" => nil }, RbConfig.ruby, "-rbundler/setup", *command, chdir: root)
		assert(status.success?) { error }
		output
	end

	def boot(root, script)
		File.write(File.join(root, "script.rb"), <<~RUBY)
			# frozen_string_literal: true

			require_relative "config/environment"

			result = begin
				#{script}
			end

			puts JSON.dump(result)
		RUBY

		JSON.parse(run_in(root, "script.rb").lines.last)
	end

	test "components are compiled by default once a production app boots" do
		with_app do |root|
			assert_equal boot(root, <<~RUBY), [true, true, true, "<div>card</div>"]
				[
					App.config.phlex.compile,
					Phlex::Compiler.enabled?,
					compiled_method?(Card, :view_template),
					Card.new.call,
				]
			RUBY
		end
	end

	test "a component that says compile false isn't compiled at boot" do
		files = {
			"app/components/legacy.rb" => <<~RUBY,
				# frozen_string_literal: true

				class Legacy < Phlex::HTML
					compile false

					def view_template = div { "legacy" }
				end
			RUBY
		}

		with_app(files:) do |root|
			assert_equal boot(root, "[compiled_method?(Legacy, :view_template), Legacy.call]"), [false, "<div>legacy</div>"]
		end
	end

	test "components are compiled as soon as they're autoloaded in development" do
		with_app(env: "development") do |root|
			assert_equal boot(root, <<~RUBY), [true, true]
				[
					!Object.autoload?(:Card).nil?,
					compiled_method?(Card, :view_template),
				]
			RUBY
		end
	end

	test "reloading compiles the new class and forgets the old one" do
		with_app(env: "development") do |root|
			assert_equal boot(root, <<~RUBY), [true, false, true, "<div>card</div>"]
				old = Card
				old_path = old.instance_method(:view_template).source_location[0]
				was_mapped = Phlex.__compiled_source_maps__.key?(old_path)

				Rails.application.reloader.reload!

				[
					was_mapped,
					Phlex.__compiled_source_maps__.key?(old_path),
					!Card.equal?(old) && compiled_method?(Card, :view_template),
					Card.new.call,
				]
			RUBY
		end
	end

	test "setting config.phlex.compile to false leaves components uncompiled" do
		with_app(config: "config.phlex.compile = false") do |root|
			assert_equal boot(root, <<~RUBY), [false, false, "<div>card</div>"]
				[
					Phlex::Compiler.enabled?,
					compiled_method?(Card, :view_template),
					Card.new.call,
				]
			RUBY
		end
	end

	test "a component that can't be compiled is reported to the failure handler and renders uncompiled" do
		files = {
			"app/components/delegating.rb" => <<~RUBY,
				# frozen_string_literal: true

				class Delegating < Phlex::HTML
					def view_template = delegate("delegated")

					ruby2_keywords def delegate(*args) = div { plain(*args) }
				end
			RUBY
		}

		with_app(files:, config: "config.phlex.on_compile_failure = -> (component, error) { FAILURES << [component.name, error.class.name] }") do |root|
			assert_equal boot(root, "[FAILURES, Delegating.new.call]"), [[["Delegating", "Phlex::Compiler::Error"]], "<div>delegated</div>"]
		end
	end

	test "phlex:explain lists what each component leaves to the runtime" do
		files = {
			"app/components/card.rb" => CARD,
			"app/components/legacy.rb" => <<~RUBY,
				# frozen_string_literal: true

				class Legacy < Phlex::HTML
					compile false

					def view_template = div(**{}) { "legacy" }
				end
			RUBY
			"app/components/splatted.rb" => <<~RUBY,
				# frozen_string_literal: true

				class Splatted < Phlex::HTML
					def initialize(**attributes) = @attributes = attributes

					def view_template = div(**@attributes) { "splatted" }
				end
			RUBY
		}

		with_app(files:) do |root|
			assert_equal run_in(root, "-e", "require 'rake'; Rake.application.run(ARGV)", "phlex:explain"), <<~TEXT
				app/components/legacy.rb:3: Legacy says compile false, so it and its subclasses render uncompiled
				app/components/splatted.rb:6: div's attributes are serialised together because a key is splatted or isn't a literal
			TEXT
		end
	end

	test "phlex:explain says when everything compiles" do
		with_app do |root|
			assert_equal run_in(root, "-e", "require 'rake'; Rake.application.run(ARGV)", "phlex:explain"), <<~TEXT
				Every component compiles in full.
			TEXT
		end
	end
end
