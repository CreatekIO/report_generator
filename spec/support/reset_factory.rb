RSpec.configure do |config|
  config.after do
    ReportGenerator::Factory.instance_variable_set(:@registered_report_types, {})
  end
end
