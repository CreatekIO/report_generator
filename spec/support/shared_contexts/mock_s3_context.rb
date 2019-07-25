RSpec.shared_context 'mock S3' do
  let(:s3_config) do
    {
      bucket_name: 'test-bucket',
      access_key_id: 'test_access_key_id',
      secret_access_key: 'test_secret_access_key'
    }
  end

  let(:s3_store) do
    Dragonfly::S3DataStore.new(s3_config)
  end

  around do |example|
    require 'dragonfly/s3_data_store'

    Fog.mock!

    example.run

    Fog::Mock.reset # clear out all uploads
    Fog.unmock!
  end

  before do
    allow(Dragonfly.app).to receive(:datastore).and_return(s3_store)
  end
end
