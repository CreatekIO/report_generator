module ReportGenerator
  class DownloadsController < ReportGenerator.parent_controller
    # Order is important here - because ExpiredSignature is a subclass
    # of DecodeError, it should come first, otherwise Rails will always
    # use the handler for DecodeError
    rescue_from 'JWT::DecodeError', with: :jwt_invalid
    rescue_from 'JWT::ExpiredSignature', with: :jwt_expired
    rescue_from 'ActiveRecord::RecordNotFound', with: :download_not_found

    def show
      download = ReportGenerator.download_class.from_jwt(params[:token])

      redirect_to download.expiring_link(expires_in: 5.minutes)
    end

    def create
      ReportGenerator.worker_class.perform_async(
        ReportGenerator.download_class.create_from!(report_download_params).id
      )

      head :created
    end

    private

    def report_download_params
      given_params = params
        .require(:report_download)
        .permit!
        .to_unsafe_h.map { |k, v| [k.underscore.to_sym, v] }
        .to_h

      return process_report_download_params(given_params) if respond_to?(:process_report_download_params)

      given_params
    end

    def jwt_expired
      redirect_with_message(ReportGenerator.config.jwt_expired_message)
    end

    def jwt_invalid
      redirect_with_message(ReportGenerator.config.jwt_invalid_message)
    end

    def download_not_found
      redirect_with_message(ReportGenerator.config.download_not_found_message)
    end

    def redirect_with_message(message)
      location = request.referrer.presence || '/'

      redirect_to location, alert: message
    end
  end
end
