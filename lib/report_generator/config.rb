require 'singleton'

module ReportGenerator
  class Config
    include Singleton

    attr_accessor :admin_class, :modal_content
    attr_writer :download_class, :worker_class, :parent_controller, :html_sanitizer

    def download_class
      @download_class ||= 'ReportGenerator::Download'
    end

    def worker_class
      @worker_class ||= 'ReportGenerator::Worker'
    end

    def parent_controller
      @parent_controller ||= 'ApplicationController'
    end

    def html_sanitizer
      @html_sanitizer ||= begin
        if defined?(ActionView::Base)
          ActionView::Base.full_sanitizer
        else
          Rails::Html::Sanitizer.full_sanitizer.new
        end
      end
    end
  end
end
