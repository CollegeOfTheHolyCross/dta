source 'https://rubygems.org'
source 'https://rails-assets.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Outdated to make this work
gem 'leaflet-rails', '0.7.7'

# Fonts
gem 'lato-rails'

#gem 'mysql2', '0.4.10'
# Temporary
gem 'active-fedora', '11.5.2'

# Maybe Temporary
gem 'noid-rails'
gem 'geomash', github: 'samvera-labs/geomash'
gem 'secondbase'

ruby '2.4.0'

# File Upload Library
gem "refile", require: "refile/rails"
gem 'mime-types'

# From original dta
#gem 'acts-as-taggable-on', '~> 4.0'
gem 'acts-as-taggable-on', '~> 5'
#Fix the 4kb session limit
gem 'activerecord-session_store'

# End from original dta

# Blacklight stuff
gem "blacklight_advanced_search"
gem "blacklight", "~> 6"
gem "blacklight-gallery"
gem "blacklight_range_limit"
gem "blacklight-maps", github: 'projectblacklight/blacklight-maps'
# End Blacklight

# Authentication
gem 'devise'
gem 'devise-guests'
# End Authentication

# Other
gem 'friendly_id', '5.1.0'
gem 'gon'
# End Other

# Adding in form dependencies
gem 'ckeditor', '4.2.4'
gem 'simple_form'
gem "rails-assets-onmount"
gem 'select2-rails'
# End Adding in

# Date Support
gem 'edtf'
gem 'edtf-humanize'
# End Date Support

# Linked Data
gem 'rdf-blazegraph', github: "ruby-rdf/rdf-blazegraph", branch: 'develop'
gem 'active-triples', github: "scande3/ActiveTriples", branch: 'develop'
# End Linked Data

# File parsing / conversion dependencies
gem "mini_magick"
gem "pdf-reader"

# Background jobs
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-statistic'
gem 'tilt' # Required for sidekiq-statistic

# Versioning
gem 'paper_trail'

# Analytics
gem 'ahoy_matey'

# Blazer
gem 'blazer', github: "scande3/blazer", branch: 'develop'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0.rc1'
#gem 'rails', '~> 5.1.4', github: 'scande3/rails', branch: 'bugfix/v5.1.4'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

gem 'rsolr', '>= 1.0', '< 3'
