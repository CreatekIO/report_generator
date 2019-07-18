module ReportGenerator
  class Worker
    include Sidekiq::Worker

    sidekiq_options retry: false, queue: 'reports'

    def perform(report_download_id)
      ReportGenerator.process(report_download_id)
    end
  end
end
