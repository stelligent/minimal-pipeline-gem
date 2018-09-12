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

    describe 'with keystore_kms_id' do
      before(:all) do
        ENV['keystore_kms_id'] = '12345'
      end

      after(:all) do
        ENV.delete('keystore_kms_id')
      end

      it 'instantiates a crossing object' do
        s3 = double(Aws::S3::Encryption::Client)
        expect(Aws::S3::Encryption::Client).to receive(:new).and_return(s3)

        kms = double(Aws::KMS::Client)
        expect(Aws::KMS::Client).to receive(:new).and_return(kms)

        expect(Crossing).to receive(:new).with(s3)

        crossing = MinimalPipeline::Crossing.new
      end

      it 'uploads content to S3' do
        crossing_mock = double(Crossing)
        expect(Crossing).to receive(:new).and_return(crossing_mock)

        expect(crossing_mock).to receive(:put_content).with('bucket_name',
                                                            'file_name',
                                                            'foo')

        crossing = MinimalPipeline::Crossing.new
        crossing.upload_content('bucket_name', 'file_name', 'foo')
      end

      it 'downloads content form S3' do
        crossing_mock = double(Crossing)
        expect(Crossing).to receive(:new).and_return(crossing_mock)

        expect(crossing_mock).to receive(:get_content).with('bucket_name',
                                                            'file_name')

        crossing = MinimalPipeline::Crossing.new
        crossing.download_file('bucket_name', 'file_name')
      end
    end
  end
end
