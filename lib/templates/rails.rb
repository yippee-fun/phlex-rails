# Rails application template
# https://guides.rubyonrails.org/rails_application_templates.html

gem "phlex-rails"

use_literal = while true
	case ask("Use literal in base component? [Y/n]")
	when "", /y/i then break true
	when /n/i then break false
	end
end
literal_gem_flag =  use_literal ? "--use-literal-gem" : "--no-use-literal-gem"

gem "literal" if use_literal

after_bundle do
  generate "phlex:install", literal_gem_flag
  puts "Phlex installed for rails project"
end
