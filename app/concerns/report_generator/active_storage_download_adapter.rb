module ReportGenerator::ActiveStorageDownloadAdapter
  extend ActiveSupport::Concern

  included do
    has_one_attached :report
  end

  def expiring_link(expires_in: ReportGenerator::Download::MAX_EXPIRY)
    self.report.service_url(expires_in: expires_in.to_i, disposition: "attachment")
  end
end
