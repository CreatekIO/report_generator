RSpec.describe ReportGenerator do
  it 'has a version number' do
    expect(ReportGenerator::VERSION).not_to be nil
  end

  describe '.config' do
    it 'returns the config instance' do
      expect(described_class.config).to be_a(described_class::Config)
    end
  end

  describe '.configure' do
    it 'yields the config instance' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(
        an_instance_of(described_class::Config)
      )
    end
  end

  describe '.download_class' do
    it 'returns constant from string value' do
      stub_const('TestModel', Class.new)

      with_config do |config|
        config.download_class = TestModel.name

        expect(described_class.download_class).to eq(TestModel)
      end
    end
  end

  describe '.worker_class' do
    it 'returns constant from string value' do
      stub_const('TestWorker', Class.new)

      with_config do |config|
        config.worker_class = TestWorker.name

        expect(described_class.worker_class).to eq(TestWorker)
      end
    end
  end

  describe '.process' do
    let(:report_type) { 'testing_report_generator_process' }

    let(:generator_class) do
      Class.new(described_class::Abstract)
    end

    let!(:download) { described_class::Download.create!(report_type: report_type) }
    let(:spy_for_generate_method) { spy }

    before do
      spy_var = spy_for_generate_method # capture spy in local scope
      generator_class.registers(report_type)
      generator_class.send(:define_method, :generate) { spy_var.called }
    end

    it 'calls #generate on an instance of the generator' do
      described_class.process(download.id)

      expect(spy_for_generate_method).to have_received(:called)
    end
  end
end
