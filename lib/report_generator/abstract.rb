require 'tempfile'

module ReportGenerator
  class Abstract
    BYTE_ORDER_MARK = "\xEF\xBB\xBF".freeze

    def initialize(report_download)
      @report_download = report_download
    end

    def self.registers(report_type)
      Factory.register(report_type, self)
    end

    def generate
      if ReportGenerator.config.download_adapter == 'ActiveStorage'
        report_download.report.attach(io: File.open(tempfile), filename: file_name, content_type: "text/csv")
      else
        report_download.file = tempfile
        report_download.file.name = file_name
      end
      report_download.generated_at = Time.now
      report_download.save!
      report_download.set_expiring_link!
      report_download
    end

    def tempfile
      Tempfile.open(['report', '.csv']) do |file|
        file.write(BYTE_ORDER_MARK)
        file.write(csv_string)
        file
      end
    end

    private

    attr_reader :report_download

    def file_name
      "#{report_download.report_type}_report.csv"
    end

    def csv_string
      raise NotImplementedError
    end
  end
end
