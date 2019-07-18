require 'report_generator/version'
require 'report_generator/config'

module ReportGenerator
  class Error < StandardError; end

  class << self
    def config
      Config.instance
    end

    def configure
      yield(config)
    end

    def download_class
      @download_class ||= config.download_class.constantize
    end
  end
end
