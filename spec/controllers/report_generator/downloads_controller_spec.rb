require 'spec_helper'
require_relative '../../../app/workers/report_generator/worker'
require_relative '../../../app/controllers/report_generator/downloads_controller'
require_relative '../../../config/routes'

RSpec.describe ReportGenerator::DownloadsController do
  include RSpec::Rails::ControllerExampleGroup

  before do
    allow(controller).to receive(:_routes).and_return(routes)
  end

  describe 'GET show' do
    include_context 'mock S3'

    let(:report_download) do
      ReportGenerator.download_class.create!(
        report_type: 'testing_get_show',
        file_uid: '1234/file.csv'
      )
    end

    subject { get :show, params: { token: jwt } }

    before do
      with_config do |config|
        config.jwt_hmac_secret = 'test secret'
        config.jwt_expired_message = 'jwt_expired_message'
        config.jwt_invalid_message = ' jwt_invalid_message'
        config.download_not_found_message = 'download_not_found_message'
      end
    end

    context 'with valid token' do
      let(:jwt) { report_download.to_jwt }

      it 'redirects to report on S3 with a short-lived link' do
        subject

        aggregate_failures do
          expect(response).to redirect_to(
            a_string_including(".s3.amazonaws.com/#{report_download.file_uid}")
          )

          location_params = Rack::Utils.parse_query(
            URI.parse(response.location).query
          )

          expect(location_params['X-Amz-Signature']).to be_present
          expect(Integer(location_params['X-Amz-Expires'])).to be_within(5.seconds).of(5.minutes.to_i)
        end
      end
    end

    context 'with expired token' do
      let(:jwt) do
        travel_to(7.days.ago) { report_download.to_jwt }
      end

      it 'redirects with an error' do
        subject

        aggregate_failures do
          expect(response).to redirect_to('/')
          expect(flash.alert).to eq(ReportGenerator.config.jwt_expired_message)
        end
      end
    end

    context 'with invalid token' do
      let(:jwt) { 'not_a_token' }

      it 'redirects with an error' do
        subject

        aggregate_failures do
          expect(response).to redirect_to('/')
          expect(flash.alert).to eq(ReportGenerator.config.jwt_invalid_message)
        end
      end
    end

    context 'with non-existent report' do
      let(:jwt) { ReportGenerator.download_class.new(id: 1_000_000).to_jwt }

      it 'redirects with an error' do
        subject

        aggregate_failures do
          expect(response).to redirect_to('/')
          expect(flash.alert).to eq(ReportGenerator.config.download_not_found_message)
        end
      end
    end
  end

  describe 'POST create' do
    let(:report_download_params) do
      { report_download: { report_type: 'custom_reports', report_programme_id: 1 } }
    end

    before do
      allow(ReportGenerator::Worker).to receive(:perform_async)
    end

    subject do
      post :create, params: report_download_params
    end

    it 'successfully starts the report worker' do
      subject

      expect(ReportGenerator::Worker).to have_received(:perform_async)
    end

    context 'when there are no errors' do
      it 'creates a report download' do
        expect do
          subject
        end.to change(ReportGenerator::Download, :count).by(1)
      end

      it 'returns a 201' do
        subject

        expect(response.status).to eq(201)
      end
    end

    context 'when required params are missing' do
      let(:report_download_params) do
        { report_download: { report_type: '' } }
      end

      it 'returns record invalid' do
        expect do
          subject
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
