require 'dragonfly'

module ReportGenerator
  class Download < ActiveRecord::Base
    extend Dragonfly::Model

    self.table_name = 'report_downloads'

    has_one :admin_report_download, class_name: 'ReportGenerator::AdminDownload', foreign_key: :report_download_id
    has_one :admin, through: :admin_report_download
    accepts_nested_attributes_for :admin_report_download

    serialize :report_data, Hash

    dragonfly_accessor :file

    validates :report_type, presence: true

    # Max value for `X-Amz-Expires` header
    MAX_EXPIRY = 7.days.to_i
    EXPIRY_OFFSET = 7.days - 1.hour - 2.minutes

    def set_expiring_link!
      return if remote_file_url.present?

      # This mirrors the logic used by Fog to calculate the `X-Amz-Expires`
      # header, so that we always get a valid value.
      # See: https://github.com/fog/fog-aws/blob/v2.0.0/lib/fog/aws/storage.rb#L178-L185
      now = defined?(Fog) ? Fog::Time.now : Time.now
      expires_at = now + EXPIRY_OFFSET
      expires_at -= 60.seconds while (expires_at.to_i - now.to_i) > MAX_EXPIRY

      self.remote_file_url = file.remote_url(expires: expires_at)
      save!
    end

    class << self
      def create_from!(params)
        build_from(params).tap(&:save!)
      end

      def build_from(params)
        new(
          {
            report_type: params[:report_type],
            admin_report_download_attributes: admin_attributes(params),
            report_data: report_data_from_params(params),
            send_email: user_asked_for_email?(params)
          }.reject { |_, v| v.nil? }
        )
      end

      def admin_attributes(params)
        { admin_id: params.fetch(:report_admin_id) }
      rescue KeyError
        nil
      end

      def report_data_from_params(params)
        params.except(
          :report_type,
          :report_admin_id,
          :report_url,
          :send_email
        ).map { |k, v| [k.to_s.gsub('report_', '').to_sym, v] }.to_h
      end

      def user_asked_for_email?(params)
        params[:send_email] == 'true'
      end
    end
  end
end
