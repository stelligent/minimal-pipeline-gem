# frozen_string_literal: true

require 'keystore'
require 'aws-sdk'

class MinimalPipeline
  # Here is an example of how to use this class to interact with the Keystore.
  #
  # ```
  # keystore = MinimalPipeline::Keystore.new
  #
  # # Store
  # keystore.store('EXAMPLE_KEY', 'foo')
  #
  # # Retrieve
  # content = keystore.retrieve('EXAMPLE_KEY')
  # puts content # Outputs 'foo'
  # ```
  #
  # You will need the following environment variables to be present:
  # * `AWS_REGION` or `region`
  # * `keystore_table`
  # * `keystore_kms_id`
  #
  # For more information on the Keystore please see
  # https://github.com/stelligent/keystore
  class Keystore
    # Initializes a `Keystore` client
    # Requires environment variables `AWS_REGION` or `region` to be set.
    # Also requires `keystore_table` and `keystore_kms_id`
    def initialize
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?
      raise 'You must set env variable keystore_table.' \
        if ENV['inventory_store'].nil? && ENV['keystore_table'].nil?
      raise 'You must set env variable keystore_kms_id.' \
        if ENV['inventory_store_key'].nil? && ENV['keystore_kms_id'].nil?

      region = ENV['AWS_REGION'] || ENV['region']
      keystore_table = ENV['keystore_table'] || ENV['inventory_store']
      keystore_kms_id = ENV['keystore_kms_id'] || ENV['inventory_store_key']
      kms = Aws::KMS::Client.new(region: region)
      dynamo = Aws::DynamoDB::Client.new(region: region)
      @keystore = ::Keystore.new(dynamo: dynamo,
                                 table_name: keystore_table,
                                 kms: kms,
                                 key_id: keystore_kms_id)
    end

    # Retrieves a value from the Keystore
    #
    # @param keyname [String] The name of the Keystore key
    # @return [String] The value stored in the Keystore for the given key
    def retrieve(keyname)
      @keystore.retrieve(key: keyname)
    end

    # Stores a value in the Keystore
    #
    # @param keyname [String] The name of the Keystore key
    # @param value [String] The value to store for the given key
    def store(keyname, value)
      @keystore.store(key: keyname, value: value)
    end
  end
end
