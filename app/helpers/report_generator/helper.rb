module ReportGenerator
  module Helper
    def report_button(report_type, data = {})
      position = data.delete(:position)

      button_tag(
        report_generator_button_label(data),
        id: data.delete(:id) || 'export-csv-button',
        disabled: data.delete(:disabled),
        class: [
          'btn btn-default',
          *("pull-#{position || 'right'}" unless position == :inline),
          *data.delete(:button_class)
        ],
        type: 'button',
        data: {
          report_type: report_type,
          report_url: report_generator.report_downloads_path,
          toggle: 'modal',
          target: '#generate-report-modal'
        }.merge(data)
      )
    end

    def report_link(report_type, data = {})
      link_to(
        '',
        id: data.delete(:id),
        data: {
          report_type: report_type,
          report_url: report_generator.report_downloads_path,
          toggle: 'modal',
          target: '#generate-report-modal'
        }.merge(data)
      ) do
        if block_given?
          yield
        else
          report_generator_button_label(data)
        end
      end
    end

    private

    def report_generator_button_label(data)
      data.delete(:button_label) || data.delete(:link_label) || 'Export CSV'
    end
  end
end
