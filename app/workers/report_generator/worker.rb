require 'sidekiq'

module ReportGenerator
  class Worker
    include Sidekiq::Worker

    attr_reader :download

    sidekiq_options retry: false, queue: 'reports'

    def perform(report_download_id)
      @download = ReportGenerator.process(report_download_id)
      yield(download) if block_given?
    end
  end
end
