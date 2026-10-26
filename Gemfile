# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.4.8'

gem 'bootsnap', require: false
gem 'kamal', require: false
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rails', '~> 8.1.3'
gem 'thruster', require: false
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'dotenv-rails'
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', '~> 2.34', '>= 2.34.3', require: false
  gem 'rubocop-rspec', require: false

  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0'
end
