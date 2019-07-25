module ReportGenerator
  class Factory
    def initialize(report_download)
      @report_download = report_download
    end

    class << self
      def for(report_download)
        new(report_download).build
      end

      def register(report_type, klass)
        registered_report_types[report_type.to_sym] = klass
      end

      def registered_report_types
        @registered_report_types ||= {}
      end
    end

    def build
      service_class.new(report_download)
    end

    private

    attr_reader :report_download

    def report_type
      report_download.report_type.to_sym
    end

    def service_class
      service_mappings.fetch(report_type) do
        raise(
          ServiceNotFound,
          "No generator registered for report type: #{report_type}"
        )
      end
    end

    def service_mappings
      self.class.registered_report_types
    end
  end
end
