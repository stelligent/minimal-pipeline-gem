# frozen_string_literal: true

# Top level namespace for automation pipeline classes
class MinimalPipeline
  # autoload libraries
  autoload(:Cloudformation, 'minimal_pipeline/cloudformation')
  autoload(:Crossing, 'minimal_pipeline/crossing')
  autoload(:Docker, 'minimal_pipeline/docker')
  autoload(:Ec2, 'minimal_pipeline/ec2')
  autoload(:Keystore, 'minimal_pipeline/keystore')
  autoload(:Lambda, 'minimal_pipeline/lambda')
  autoload(:Packer, 'minimal_pipeline/packer')
  autoload(:S3, 'minimal_pipeline/s3')
  autoload(:Sqs, 'minimal_pipeline/sqs')
end
