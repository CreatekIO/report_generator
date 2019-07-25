module WithConfigHelper
  def with_config
    new_config = ReportGenerator::Config.send(:new)
    allow(ReportGenerator::Config).to receive(:instance).and_return(new_config)

    yield(new_config)
  end
end

RSpec.configure do |config|
  config.include WithConfigHelper
end
