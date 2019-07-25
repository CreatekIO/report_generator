require 'spec_helper'

RSpec.describe ReportGenerator::Download do
  describe '#set_expiring_link!' do
    include_context 'mock S3'

    context 'when 7 days from now includes BST -> GMT change' do
      let(:last_sunday_of_oct) do
        end_of_oct = Date.new(Date.today.year, 10, -1)
        end_of_oct += 1.year if end_of_oct.past?
        # subtract number of days we are ahead of Sunday
        end_of_oct - end_of_oct.wday
      end

      around do |example|
        Time.use_zone('Europe/London') { example.run }
      end

      let(:problematic_time) do
        date = last_sunday_of_oct - 7.days
        Time.zone.parse("#{date.iso8601} 09:00:00")
      end

      subject(:report_download) do
        described_class.new(
          report_type: 'testing_expiring_link_with_s3',
          file_uid: '1234/file.csv'
        )
      end

      before do
        # Make ActiveSupport::TimeWithZone quack like Fog::Time
        def problematic_time.to_iso8601_basic
          utc.strftime('%Y%m%dT%H%M%SZ')
        end

        allow(Fog::Time).to receive(:now).and_return(problematic_time)
      end

      it 'generates a valid signed URL' do
        report_download.set_expiring_link!
        report_download.reload

        params = Rack::Utils.parse_query(
          URI.parse(report_download.remote_file_url).query
        )

        aggregate_failures do
          expect(params['X-Amz-Signature']).to be_present
          expect(Integer(params['X-Amz-Expires'])).to be <= 7.days.to_i
        end
      end
    end
  end

  describe '.create_from!' do
    subject(:report_download) do
      described_class.create_from!(params)
    end

    let(:params) do
      {
        report_type: 'testing_report_generator_download_create_from',
      }.merge(param_overrides)
    end

    let(:param_overrides) { {} }

    it 'creates a report download' do
      expect do
        report_download
      end.to change(described_class, :count).by(1)
    end

    context 'when send_email is passed' do
      let(:param_overrides) { { send_email: 'false' } }

      it 'sets the send_email attribute with the correct boolean value' do
        expect(report_download.send_email).to be false
      end
    end

    context 'when other fields are passed' do
      let(:param_overrides) { { report_query: 'foo_bar' } }
      let(:expected_report_data) { { query: 'foo_bar' } }

      it 'assigns them to the report_data' do
        expect(report_download.report_data).to eq(expected_report_data)
      end
    end
  end
end
