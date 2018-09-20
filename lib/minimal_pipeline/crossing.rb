# frozen_string_literal: true

require 'aws-sdk'
require 'crossing'

class MinimalPipeline
  # Here is an example of how to use this class to interact with Crossing.
  #
  # ```
  # crossing = MinimalPipeline::Crossing.new
  #
  # # Upload
  # crossing.upload_content('my-config-bucket', 'example.txt', 'foo')
  #
  # # Download
  # content = crossing.download_file('my-config-bucket', 'example.txt')
  # puts content # Outputs 'foo'
  # ```
  #
  # You will need the following environment variables to be present:
  # * `AWS_REGION` or `region`
  # * `keystore_kms_id`
  #
  # For more information on Crossing see https://github.com/stelligent/crossing
  class Crossing
    def initialize
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?
      raise 'You must set env variable keystore_kms_id.' \
        if ENV['inventory_store_key'].nil? && ENV['keystore_kms_id'].nil?

      region = ENV['AWS_REGION'] || ENV['region']
      keystore_kms_id = ENV['keystore_kms_id'] || ENV['inventory_store_key']
      kms = Aws::KMS::Client.new(region: region)
      s3 = Aws::S3::Encryption::Client.new(kms_key_id: keystore_kms_id,
                                           kms_client: kms,
                                           region: region)
      @crossing = ::Crossing.new(s3)
    end

    # Securely uploads a file to an S3 bucket
    #
    # @param config_bucket [String] The name of the S3 bucket
    # @param filename [String] The name of the file to save content to in the
    #   bucket
    # @param content [String] The content to store in the file
    def upload_content(config_bucket, filename, content)
      @crossing.put_content(config_bucket, filename, content)
    end

    # Securely downloads a file from an S3 bucket
    #
    # @param config_bucket [String] The name of the S3 bucket
    # @param filename [String] The name of the file that contains the desired
    #  content
    # @return [String] The content that was stored in the file
    def download_file(config_bucket, filename)
      @crossing.get_content(config_bucket, filename)
    end
  end
end
