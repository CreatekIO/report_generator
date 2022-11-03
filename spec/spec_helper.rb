require 'bundler/setup'
require 'byebug'
require 'mysql2'
require 'rails/all'
require 'rspec/rails'
require 'active_support/testing/time_helpers'
require 'report_generator'
require_relative '../app/models/report_generator/download'

ENV['RAILS_ENV'] ||= 'test'

Dir[File.expand_path('./support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include ActiveSupport::Testing::TimeHelpers
end

Rails.application = ReportGenerator::Engine

db_config = {
  database: "report_generator_test#{ENV['CIRCLE_NODE_INDEX']}",
  adapter: 'mysql2',
  encoding: 'utf8mb4',
  pool: 5,
  host: ENV['DB_HOST'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD']
}.freeze

ActiveRecord::Base.logger = ActiveSupport::Logger.new(File.expand_path('../log/test.log', __dir__))
ActiveRecord::Base.try(:use_yaml_unsafe_load=, true) # for compatibility with Ruby 2.5
ActiveRecord::Base.establish_connection(db_config)

require 'active_record/tasks/database_tasks'

ActiveRecord::Tasks::DatabaseTasks.tap do |tasks|
  begin
    ActiveRecord::Base.connection
  rescue
    # Database doesn't exist, create it
    tasks.create(db_config.stringify_keys)
  end

  tasks.migrations_paths = [File.expand_path('../db/migrate', __dir__)]
  tasks.migrate rescue nil
end

class ApplicationController < ActionController::Base; end

Dragonfly.app.configure do
  datastore :file, root_path: 'tmp/dragonfly'
end
