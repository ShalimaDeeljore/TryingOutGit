
gem 'jsonapi_suite', '~> 0.7'
gem 'jsonapi-rails', '~> 0.3.0'
gem 'jsonapi_swagger_helpers', '~> 0.6', require: false
gem 'jsonapi_spec_helpers', '~> 0.4', require: false
gem 'kaminari', '~> 1.0'

gem_group :development, :test do
  gem 'rspec-rails', '~> 3.5.2'
  gem 'factory_bot_rails', '~> 4.0'
  gem 'faker', '~> 1.7' # keep here for seeds.rb
  gem 'swagger-diff', '~> 1.1'
end

gem_group :test do
  gem 'database_cleaner', '~> 1.6'
end
