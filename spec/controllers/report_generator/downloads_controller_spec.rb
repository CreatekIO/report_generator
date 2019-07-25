require 'spec_helper'
require_relative '../../../app/workers/report_generator/worker'
require_relative '../../../app/controllers/report_generator/downloads_controller'

RSpec.describe ReportGenerator::DownloadsController do
  include Rack::Test::Methods

  describe 'POST create' do
    let(:report_download_params) do
      { report_download: { report_type: 'custom_reports', report_programme_id: 1 } }
    end

    before do
      allow(ReportGenerator::Worker).to receive(:perform_async)
    end

    def app
      app = described_class.action(:create)

      Rack::Builder.new do
        map '/' do
          run app
        end
      end
    end

    subject do
      post '/', report_download_params
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

        expect(last_response.status).to eq(201)
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
