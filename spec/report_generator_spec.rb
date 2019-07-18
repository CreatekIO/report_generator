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
    TestModel = Class.new

    before do
      config = double('Config', download_class: TestModel.name)
      allow(described_class).to receive(:config).and_return(config)
    end

    after do
      described_class.instance_variable_set(:@download_class, nil)
    end

    it 'returns constant from string value' do
      expect(described_class.download_class).to eq(TestModel)
    end
  end
end
