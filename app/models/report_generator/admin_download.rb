module ReportGenerator
  class AdminDownload < ActiveRecord::Base
    self.table_name = 'admin_report_downloads'

    belongs_to :admin, class_name: ReportGenerator.config.admin_class.to_s
    belongs_to :report_download, class_name: ReportGenerator.config.download_class.to_s
  end
end
