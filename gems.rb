say(set_color(welcome.rstrip, :cyan, :bold))
api_namespace

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

insert_into_file "config/routes.rb", :after => "Rails.application.routes.draw do\n" do
  <<-STR
  scope path: '/#{api_namespace}' do
    scope path: '/v1' do
      # your routes go here
    end
  end
  STR
end

after_bundle do
run 'bin/spring stop'

run "bundle binstub rspec-core"
rails_command "generate rspec:install"
run "rm -rf test"

git :init
git add: '.'
insert_into_file "spec/rails_helper.rb", :after => "require 'rspec/rails'\n" do
  "require 'jsonapi_spec_helpers'\n"
end

insert_into_file "spec/rails_helper.rb", :after => "RSpec.configure do |config|\n" do
  <<-STR
  # bootstrap database cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  config.around(:each) do |example|
    begin
      DatabaseCleaner.cleaning do
        example.run
      end
    ensure
      DatabaseCleaner.clean
    end
  end
  STR
end

insert_into_file "spec/rails_helper.rb", :after => "RSpec.configure do |config|\n" do
  <<-STR
  config.before :each do
    JsonapiErrorable.disable!
  end
  STR
end

insert_into_file "spec/rails_helper.rb", :after => "RSpec.configure do |config|\n" do
  "  config.include JsonapiSpecHelpers\n"
end

insert_into_file "spec/rails_helper.rb", :after => "RSpec.configure do |config|\n" do
  "  config.include FactoryBot::Syntax::Methods\n"
end

gsub_file "spec/rails_helper.rb", 'config.fixture_path = "#{::Rails.root}/spec/fixtures"' do |match|
  "# #{match}"
end

gsub_file "spec/rails_helper.rb", 'config.use_transactional_fixtures = true' do |match|
  "# #{match}"
end

run "mkdir spec/payloads"
run "mkdir spec/factories"
run "mkdir -p spec/api/v1"

rails_command('generate jsonapi_suite:install')
# swagger
run "mkdir -p public/#{api_namespace}/docs"
inside("public/#{api_namespace}/docs") do
  run "git clone https://github.com/jsonapi-suite/swagger-ui.git && cp swagger-ui/prod-dist/* . && rm -rf swagger-ui"
end

gsub_file "public/#{api_namespace}/docs/index.html", "basePath: '/api'" do
  "basePath: '/#{api_namespace}'"
end

gsub_file "public/#{api_namespace}/docs/index.html", "/app." do |match|
  "/#{api_namespace}/docs#{match}"
end

github = prompt \
  header: "What is the Github URL for this project?",
  description: "This is used in the Swagger UI to link to your project. It does *not* end in .git. If you don't have a Github URL yet, make sure to edit public/#{api_namespace}/docs/index.html once you have one",
  default: 'nil'

if github.present?
  gsub_file "public/#{api_namespace}/docs/index.html", "githubURL: 'http://replaceme.com'" do
    "githubURL: '#{github}'"
  end
end

create_file 'app/controllers/docs_controller.rb' do
  title = prompt \
    header: "What is the Swagger title for this project?",
    description: "Should make sense in the sentence, 'Welcome to the <title> API'",
    default: 'Untitled'
  description = prompt \
    header: "What is the Swagger description for this project?",
    description: "HTML is OK here",
    default: '--'
  contact_name = prompt \
    header: "What is the Swagger contact name?",
    description: "e.g. 'John Doe'",
    default: '--'
  contact_email = prompt \
    header: "What is the Swagger contact email?",
    default: '--'

  <<-STR
require 'jsonapi_swagger_helpers'
class DocsController < ActionController::API
  include JsonapiSwaggerHelpers::DocsControllerMixin
  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, '#{title}'
      key :description, '#{description}'
      contact do
        key :name, '#{contact_name}'
        key :email, '#{contact_email}'
      end
    end
    key :basePath, '/#{api_namespace}'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end
end
  STR
end

insert_into_file "config/routes.rb", after: "scope path: '/#{api_namespace}' do\n" do
  "    resources :docs, only: [:index], path: '/swagger'\n\n"
end

insert_into_file "Rakefile", after: "require_relative 'config/application'\n" do
  "require 'jsonapi_swagger_helpers'\n"
end
