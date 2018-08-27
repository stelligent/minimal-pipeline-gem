require './spec/spec_helper'

describe MinimalPipeline::Crossing do
  describe 'without AWS_REGION' do
    it 'requires AWS_REGION to be set' do
      expect {
        crossing = MinimalPipeline::Crossing.new
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

    it 'requires keystore_kms_id' do
      expect {
        crossing = MinimalPipeline::Crossing.new
      }.to raise_error 'You must set env variable keystore_kms_id.'
    end
  end
end
