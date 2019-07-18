require 'spec_helper'

RSpec.describe ReportGenerator::Factory do
  describe '.register' do
    let(:report_download) do
      instance_double('ReportDownload', report_type: 'foo_bar')
    end
    let(:dummy_klass) { Class.new }

    it 'registers a generator' do
      described_class.register(:foo_bar, dummy_klass)

      expect(described_class.registered_report_types).to include(
        foo_bar: dummy_klass
      )
    end
  end

  describe '.for' do
    subject(:generator) { described_class.for(report_download) }

    let(:report_download) do
      instance_double('ReportDownload', report_type: report_type)
    end
    let(:report_type) { 'foo_bar' }

    context 'when the report type is' do
      context 'registered' do
        let(:dummy_klass) do
          Class.new do
            def initialize(_); end
          end
        end

        before do
         described_class.register(:foo_bar, dummy_klass)
        end

        it { is_expected.to be_an_instance_of(dummy_klass) }
      end

      context 'not registered' do
        let(:report_type) { 'non_existent' }

        it 'raises a ServiceNotFound error' do
          expect { generator }.to raise_error(
            ReportGenerator::ServiceNotFound,
            /No generator registered for report type/
          )
        end
      end
    end
  end
end
