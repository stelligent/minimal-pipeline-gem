require 'rspec'
require 'minimal_pipeline'

describe MinimalPipeline::Keystore do
  describe 'without AWS_REGION' do
    it 'requires AWS_REGION to be set' do
      expect {
        keystore = MinimalPipeline::Keystore.new
      }.to raise_error 'You must set env variable AWS_REGION or region.'
    end
  end

  describe 'with AWS_REGION' do
    before(:all) do
      ENV['AWS_REGION'] = 'us-east-1'
    end

    after(:all) do
      ENV.delete('AWS_REGION')
    end

    it 'requires keystore_table' do
      expect {
        keystore = MinimalPipeline::Keystore.new
      }.to raise_error 'You must set env variable keystore_table.'
    end

    it 'also requires keystore_kms_id' do
      ENV['keystore_table'] = 'foo'

      expect {
        keystore = MinimalPipeline::Keystore.new
      }.to raise_error 'You must set env variable keystore_kms_id.'

      ENV.delete('keystore_table')
    end
  end
end
