# frozen_string_literal: true

source "https://gem.coop"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem "phlex", github: "phlex-ruby/phlex"
gem "view_component"
gem "appraisal"

gem "rails"

gem "quickdraw", github: "joeldrapper/quickdraw"

group :development do
	gem "rubocop"
	gem "ruby-lsp"
	gem "bootsnap"
end
