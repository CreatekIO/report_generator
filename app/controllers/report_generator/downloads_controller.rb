module ReportGenerator
  class DownloadsController < ReportGenerator.parent_controller
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
        .map { |k, v| [k.underscore.to_sym, v] }
        .to_h

      return process_report_download_params(given_params) if respond_to?(:process_report_download_params)

      given_params
    end
  end
end
