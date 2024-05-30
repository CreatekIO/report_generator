require 'singleton'

module ReportGenerator
  class Config
    include Singleton

    attr_accessor :admin_class, :modal_content
    attr_writer :download_class, :worker_class, :parent_controller, :html_sanitizer,
      :jwt_algorithm, :jwt_hmac_secret,
      :jwt_expired_message, :jwt_invalid_message, :download_not_found_message,
      :download_adapter, :local_storage_host

    def local_storage_host
      @local_storage_host ||= ''
    end

    def download_adapter
      @download_adapter ||= 'Dragonfly'
    end

    def download_class
      @download_class ||= 'ReportGenerator::Download'
    end

    def worker_class
      @worker_class ||= 'ReportGenerator::Worker'
    end

    def parent_controller
      @parent_controller ||= 'ApplicationController'
    end

    def jwt_algorithm
      @jwt_algorithm ||= 'HS256'
    end

    def jwt_hmac_secret
      @jwt_hmac_secret.presence or raise ArgumentError, 'you must set config.jwt_hmac_secret'
    end

    def jwt_expired_message
      @jwt_expired_message ||= 'The report you requested is no longer available'
    end

    def jwt_invalid_message
      @jwt_invalid_message ||= 'The URL you provided is invalid'
    end

    def download_not_found_message
      @download_not_found_message ||= 'We could not find the report you requested'
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
