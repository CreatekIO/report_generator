require 'report_generator/version'
require 'report_generator/config'
require 'report_generator/factory'
require 'report_generator/abstract'
require 'report_generator/base'

module ReportGenerator
  class Error < StandardError; end
  class ServiceNotFound < Error; end

  class << self
    def config
      Config.instance
    end

    def configure
      yield(config)
    end

    def download_class
      config.download_class.constantize
    end

    def parent_controller
      config.parent_controller.constantize
    end

    def process(report_download_id)
      report_download = download_class.find(report_download_id)
      generator = Factory.for(report_download)

      generator.generate
    end
  end
end

require 'report_generator/rails' if defined?(Rails)
