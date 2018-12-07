require 'aws-sdk'

class MinimalPipeline
  # # For Account 1:
  # ec2 = MinimalPipeline::Ec2.new
  # block_device_mappings = ec2.prepare_snapshots_for_account('ami-id',
  #                                                           'account-id')
  #
  # # Promote AMI via SQS
  # sqs = MinimalPipeline::Sqs.new
  # sqs.send_message('queue-name', block_device_mappings.to_json)
  #
  # # For Account 2, after getting block_device_mappings
  # ec2 = MinimalPipeline::Ec2.new
  # new_mappings = ec2.copy_snapshots_in_new_account(block_device_mappings)
  # ec2.register_ami(new_mappings, 'ami-name')
  class Ec2
    # Initializes a `Ec2` client
    # Requires environment variables `AWS_REGION` or `region` to be set.
    def initialize
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?
      @region = ENV['AWS_REGION'] || ENV['region']
      @client = Aws::EC2::Client.new(region: 'us-east-1')
    end

    # Block processing until snapshot until new snapshot is ready
    #
    # @param snapshot_id [String] The ID of the new snapshot
    def wait_for_snapshot(snapshot_id)
      puts "waiting on new snapshot #{snapshot_id} to be ready"
      @client.wait_until(:snapshot_completed, snapshot_ids: [snapshot_id])
      puts "New snapshot #{snapshot_id}is ready"
    rescue Aws::Waiters::Errors::WaiterFailed => error
      puts "failed waiting for snapshot to be ready: #{error.message}"
    end

    # Create a copy of an existing snapshot
    #
    # @param snapshot_id [String] The ID of the snapshot to copy
    # @param kms_key_id [String] The ID of the KMS key. Omit to use default
    # @param encrypted [Boolean] Whether or not the volume is encrypted
    # @return [String] The ID of the newly created snapshot
    def copy_snapshot(snapshot_id, kms_key_id = nil, encrypted = true)
      params = {
        encrypted: encrypted,
        source_region: @region,
        source_snapshot_id: snapshot_id
      }
      params[:kms_key_id] = kms_key_id if kms_key_id

      new_snapshot_id = @client.copy_snapshot(params).snapshot_id

      puts "new snapshot ID: #{new_snapshot_id}"
      wait_for_snapshot(new_snapshot_id)

      new_snapshot_id
    end

    # Update permissions to grant access to an AMI on another account
    #
    # @param snapshot_id [String] The ID of the snapshot to adjust
    # @param account_id [String] The AWS account to grant access to
    def unlock_ami_for_account(snapshot_id, account_id)
      @client.modify_snapshot_attribute(
        attribute: 'createVolumePermission',
        operation_type: 'add',
        snapshot_id: snapshot_id,
        user_ids: [account_id]
      )
    end

    # Prepare volume snapshots of an AMI for a new account
    #
    # @param ami_id [String] The ID of the AMI to prepare
    # @param account_id [String] The ID of the AWS account to prepare
    # @param kms_key_id [String] The ID of the KMS key. Omit to use default
    # @return [Array] Block device mappings discovered from the AMI
    def prepare_snapshots_for_account(ami_id, account_id, kms_key_id = nil)
      images = @client.describe_images(image_ids: [ami_id])
      block_device_mappings = images.images[0].block_device_mappings
      new_mappings = []

      block_device_mappings.each do |mapping|
        snapshot_id = mapping.ebs.snapshot_id
        puts "old snapshot ID: #{snapshot_id}"
        new_snapshot_id = copy_snapshot(snapshot_id, kms_key_id)
        puts 'modifying new snapshot attribute'
        unlock_ami_for_account(new_snapshot_id, account_id)
        puts "new snapshot has been modified for the #{account_id} account"
        mapping.ebs.snapshot_id = new_snapshot_id
        new_mappings << mapping.to_hash
        puts '==========================================='
      end

      new_mappings
    end

    # Register a new AMI based on block device mappings
    # Currently only supports x86_64 HVM
    #
    # @params block_device_mappings [Array] Block device mappings with snapshots
    # @params ami_name [String] The name of the AMI to create
    # @return [String] The AMI ID of the newly created AMI
    def register_ami(block_device_mappings, ami_name)
      response = @client.register_image(
        architecture: 'x86_64',
        block_device_mappings: block_device_mappings,
        name: ami_name,
        root_device_name: '/dev/sda1',
        virtualization_type: 'hvm'
      )

      response.image_id
    end

    # Copy the snapshots from the original account into the new one
    #
    # @params block_device_mappings [Array] Block device mappings with snapshots
    # @param kms_key_id [String] The ID of the KMS key. Omit to use default
    # @return [Array] Block device mappings with updated snapshot ids
    def copy_snapshots_in_new_account(block_device_mappings, kms_key_id = nil)
      new_mappings = []

      block_device_mappings.each do |mapping|
        snapshot_id = mapping['ebs']['snapshot_id']
        new_snapshot_id = copy_snapshot(snapshot_id, kms_key_id)
        mapping['ebs']['snapshot_id'] = new_snapshot_id
        mapping['ebs'].delete('encrypted')
        new_mappings << mapping
      end

      new_mappings
    end

    # Copy an AMI
    #
    # The new image will be encrypted. You can optionally copy across regions
    #
    # @params image_id [String] The AMI ID to copy
    # @params kms_key_id [String] Non-default KMS key ID to use for encryption
    # @params region [String] The destination region for the new image
    # @return [String] The newly created AMI ID
    def copy_image(image_id, kms_key_id = nil, region = nil)
      params = {
        encrypted: true,
        source_image_id: image_id,
        source_region: @region,
        region: region || @region
      }
      params['kms_key_id'] = kms_key_id if kms_key_id

      response = @client.copy_image(params)
      response.image_id
    end
  end
end
