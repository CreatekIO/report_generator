require 'jwt'

module ReportGenerator
  class Download < ActiveRecord::Base
    include Module.const_get("ReportGenerator::#{ReportGenerator.config.download_adapter}DownloadAdapter")
    self.table_name = 'report_downloads'

    has_one(
      :admin_report_download,
      class_name: 'ReportGenerator::AdminDownload',
      foreign_key: :report_download_id,
      dependent: :destroy
    )
    has_one :admin, through: :admin_report_download
    accepts_nested_attributes_for :admin_report_download

    serialize :report_data, Hash

    validates :report_type, presence: true

    # Max value for `X-Amz-Expires` header
    MAX_EXPIRY = 7.days.to_i
    EXPIRY_OFFSET = 7.days - 1.hour - 2.minutes

    def set_expiring_link!
      return if remote_file_url.present?

      self.remote_file_url = expiring_link(expires_in: MAX_EXPIRY)
      save!
    end

    def to_jwt
      payload = {
        exp: (Time.now + MAX_EXPIRY).to_i,
        report_download_id: id
      }

      JWT.encode(
        payload,
        ReportGenerator.config.jwt_hmac_secret,
        ReportGenerator.config.jwt_algorithm
      )
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

      def from_jwt(token)
        payload, _headers = JWT.decode(
          token,
          ReportGenerator.config.jwt_hmac_secret,
          true, # should verify?
          algorithm: ReportGenerator.config.jwt_algorithm
        )

        id = payload['report_download_id'] or raise JWT::DecodeError, 'empty report_download_id'

        find(id)
      end
    end
  end
end
