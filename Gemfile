# frozen_string_literal: true

source "https://gem.coop"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem "view_component"
gem "appraisal"

gem "rails"

gem "quickdraw", github: "joeldrapper/quickdraw", ref: "06615ef2554dabec4fbf6cf2848fb9493842fd05"

group :development do
	gem "rubocop"
	gem "ruby-lsp"
	gem "bootsnap"
end
