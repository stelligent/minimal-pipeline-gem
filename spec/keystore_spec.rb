require './spec/spec_helper'

describe MinimalPipeline::Keystore do
  describe 'without AWS_REGION' do
    it 'requires AWS_REGION to be set' do
      expect do
        keystore = MinimalPipeline::Keystore.new
      end.to raise_error 'You must set env variable AWS_REGION or region.'
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
      expect do
        keystore = MinimalPipeline::Keystore.new
      end.to raise_error 'You must set env variable keystore_table.'
    end

    describe 'with keystore_table' do
      before(:all) do
        ENV['keystore_table'] = 'foo'
      end

      after(:all) do
        ENV.delete('keystore_table')
      end

      it 'also requires keystore_kms_id' do
        expect do
          keystore = MinimalPipeline::Keystore.new
        end.to raise_error 'You must set env variable keystore_kms_id.'
      end

      describe 'with keystore_kms_id' do
        before(:all) do
          ENV['keystore_kms_id'] = '12345'
        end

        after(:all) do
          ENV.delete('keystore_kms_id')
        end

        it 'instatiates a keystore object' do
          dynamo = double(Aws::DynamoDB::Client)
          expect(Aws::DynamoDB::Client).to receive(:new).and_return(dynamo)

          kms = double(Aws::KMS::Client)
          expect(Aws::KMS::Client).to receive(:new).and_return(kms)

          expect(Keystore).to receive(:new).with(
            dynamo: dynamo,
            table_name: 'foo',
            kms: kms,
            key_id: '12345'
          )

          keystore = MinimalPipeline::Keystore.new
        end

        it 'retrieves data from the keystore' do
          keystore_mock = double(Keystore)
          expect(Keystore).to receive(:new).and_return(keystore_mock)

          expect(keystore_mock).to receive(:retrieve).with(key: 'bar')

          keystore = MinimalPipeline::Keystore.new
          keystore.retrieve('bar')
        end

        it 'stores data in the keystore' do
          keystore_mock = double(Keystore)
          expect(Keystore).to receive(:new).and_return(keystore_mock)

          expect(keystore_mock).to receive(:store).with(key: 'bar',
                                                        value: 'baz')

          keystore = MinimalPipeline::Keystore.new
          keystore.store('bar', 'baz')
        end
      end
    end
  end
end
