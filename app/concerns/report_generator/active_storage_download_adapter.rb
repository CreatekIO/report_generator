module ReportGenerator::ActiveStorageDownloadAdapter
  extend ActiveSupport::Concern

  included do
    has_one_attached :report
  end

  def expiring_link(expires_in: ReportGenerator::Download::MAX_EXPIRY)
    if Rails.application.config.active_storage.service == :local
      ActiveStorage::Current.host = ReportGenerator.config.local_storage_host
    end

    self.report.service_url(expires_in: expires_in.to_i, disposition: "attachment")
  end
end
