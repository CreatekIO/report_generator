require 'csv'

module ReportGenerator
  class Base < Abstract
    class << self
      attr_accessor :columns
    end

    # Don't allow columns to be defined on Base
    self.columns = [].freeze

    delegate :columns, to: :class

    def self.column(name, options = {}, &block)
      columns << { name: name, block: block }.merge!(options).freeze
    end

    private_class_method :column

    def self.inherited(klass)
      super
      klass.columns = []
    end

    def self.inherit_columns!(except: [])
      # `deep_dup` will unfreeze the columns and the containing array
      self.columns = superclass.columns.deep_dup

      if except.present?
        except = Array.wrap(except).map(&:downcase)
        columns.reject! { |column| except.include?(column[:name].downcase) }
      end
    end

    def self.column_names
      columns.map { |column| column[:name] }
    end

    private_class_method :inherit_columns!

    def csv_string
      CSV.generate(headers: true) do |csv|
        csv << headers

        each_row do |record|
          csv << generate_row(record)
        end
      end
    end

    private

    def headers
      filtered_columns.map do |column|
        column[:name]
      end
    end

    def each_row(&block)
      collection.each(&block)
    end

    def generate_row(record)
      filtered_columns.map do |column|
        instance_exec(record, &column[:block])
      end
    end

    def filtered_columns
      @filtered_columns ||= columns.select do |column|
        column[:if].blank? || send(column[:if])
      end
    end

    def collection
      raise NotImplementedError
    end

    def data
      report_download.report_data
    end

    def sanitize_html(html)
      ReportGenerator.config.html_sanitizer.sanitize(html, tags: [])
    end
  end
end
