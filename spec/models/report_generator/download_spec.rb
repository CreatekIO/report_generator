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

  describe '.to_jwt' do
    it 'creates a valid JWT' do
      secret = 'test secret'
      algorithm = 'HS256'
      report_download = described_class.create!(report_type: 'testing_to_jwt')

      with_config do |config|
        config.jwt_hmac_secret = secret
        config.jwt_algorithm = algorithm

        jwt = report_download.to_jwt

        aggregate_failures do
          expect(JWT.decode(jwt, secret, true, algorithm: algorithm)).to match(
            [
              {
                'exp' =>  a_value_within(5.seconds).of(7.days.from_now.to_i),
                'report_download_id' => report_download.id
              },
              { 'alg' => algorithm, 'typ' => 'JWT' }
            ]
          )
          expect(described_class.from_jwt(jwt)).to eq(report_download)
        end
      end
    end
  end

  describe '.from_jwt' do
    # This value generated on:
    # https://jwt.io/#debugger-io?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1Njg2MzE4NDUsInJlcG9ydF9kb3dubG9hZF9pZCI6OTk5fQ.k3WdQ8JSb42vocyn4FYrAZTZ4Y1s1gJMlI7c2AOEvhQ
    # using the settings below
    let(:jwt) do
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1Njg2MzE4NDUsInJlcG9ydF9kb3dubG9hZF9pZCI6OTk5fQ.k3WdQ8JSb42vocyn4FYrAZTZ4Y1s1gJMlI7c2AOEvhQ'
    end

    let(:secret) { 'test secret' }
    let(:exp) { 1568631845 }
    let(:id) { 999 }

    let!(:report_download) { described_class.new(id: id) }

    before do
      allow(described_class).to receive(:find).with(id).and_return(report_download)
    end

    context 'when token has not expired' do
      around do |example|
        expiry_time = Time.at(exp)

        travel_to(expiry_time - 1.second) { example.run }
      end

      it 'finds the correct download' do
        with_config do |config|
          config.jwt_hmac_secret = secret

          expect(described_class.from_jwt(jwt)).to eq(report_download)
        end
      end
    end

    context 'when token has expired' do
      around do |example|
        expiry_time = Time.at(exp)

        travel_to(expiry_time) { example.run }
      end

      it 'raises error' do
        with_config do |config|
          config.jwt_hmac_secret = secret

          expect { described_class.from_jwt(jwt) }.to raise_error(JWT::ExpiredSignature)
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
