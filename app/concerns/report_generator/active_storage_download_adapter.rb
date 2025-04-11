module ReportGenerator::ActiveStorageDownloadAdapter
  extend ActiveSupport::Concern

  included do
    has_one_attached :report
  end

  def expiring_link(expires_in: ReportGenerator::Download::MAX_EXPIRY)
    return self.remote_file_url if self.remote_file_url.present? && !self.report.attached?

    if %i[local test].include?(Rails.application.config.active_storage.service)
      ActiveStorage::Current.host = ReportGenerator.config.local_storage_host
    end

    self.report.url(expires_in: expires_in.to_i, disposition: "attachment")
  end
end
