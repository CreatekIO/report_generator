require 'singleton'

module ReportGenerator
  class Config
    include Singleton

    attr_accessor :admin_class
    attr_writer :download_class, :html_sanitizer

    def download_class
      @download_class ||= 'ReportGenerator::Download'
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
