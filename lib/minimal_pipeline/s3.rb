# frozen_string_literal: true

require 'aws-sdk-s3'

class MinimalPipeline
  # Here is an example of how to use this class to interact with S3.
  #
  # ```
  # s3 = MinimalPipeline::S3.new
  #
  # # Upload file
  # s3.upload('bucket_name', 'foo.txt')
  #
  # # Download file
  # s3.download('bucket_name', 'foo.txt')
  # ```
  #
  # You will need the following environment variables to be present:
  # * `AWS_REGION` or `region`
  class S3
    # Initializes a `S3` client
    # Requires environment variables `AWS_REGION` or `region` to be set.
    def initialize
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?

      region = ENV['AWS_REGION'] || ENV['region']
      @s3 = Aws::S3::Resource.new(region: region)
    end

    # Downloads a file from S3 to local disk
    #
    # @param bucket_name [String] The name of S3 bucket to download from
    # @param file [String] The path to the file on disk to download to
    # @param key [String] The name of the key of the object in S3
    # This defaults to the file param
    def download(bucket_name, file, key = nil)
      key ||= File.basename(file)
      object = @s3.bucket(bucket_name).object(key)
      object.download_file(file)
    end

    # Uploads a file from local disk to S3
    #
    # @param bucket_name [String] The name of S3 bucket to upload to
    # @param file [String] The path to the file on disk to be uploaded
    # @param key [String] The name of the key to store the file as in the bucket
    # This defaults to the file param
    # @return [String] The Version ID of the latest object
    def upload(bucket_name, file, key = nil)
      key ||= File.basename(file)
      object = @s3.bucket(bucket_name).object(key)
      object.upload_file(file)
      object.load
      object.version_id
    end
  end
end
