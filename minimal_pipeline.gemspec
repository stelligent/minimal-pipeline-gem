# frozen_string_literal: true

lib = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'minimal_pipeline'
  spec.authors       = ['Mayowa Aladeojebi', 'Jesse Adams']
  spec.email         = ['mayowa.aladeojebi@stelligent.com',
                        'jesse.adams@stelligent.com']
  spec.version       = '0.3.3'
  spec.summary       = 'Helper gem to manage pipeline tasks'
  spec.description   = 'Helper gem to orchestrate pipeline tasks'
  spec.homepage      = 'https://github.com/stelligent/minimal-pipeline-gem'
  spec.license       = '0BSD'

  spec.files = ['lib/minimal_pipeline.rb',
                'lib/minimal_pipeline/cloudformation.rb',
                'lib/minimal_pipeline/keystore.rb',
                'lib/minimal_pipeline/crossing.rb',
                'lib/minimal_pipeline/docker.rb',
                'lib/minimal_pipeline/packer.rb',
                'lib/minimal_pipeline/s3.rb',
                'lib/minimal_pipeline/sqs.rb',
                'lib/minimal_pipeline/lambda.rb',
                'lib/minimal_pipeline/ec2.rb']
  spec.require_paths = ['lib']
  spec.add_runtime_dependency('aws-sdk-cloudformation')
  spec.add_runtime_dependency('aws-sdk-ec2')
  spec.add_runtime_dependency('aws-sdk-lambda')
  spec.add_runtime_dependency('aws-sdk-s3')
  spec.add_runtime_dependency('aws-sdk-sqs')
  spec.add_runtime_dependency('crossing', '~> 0.1')
  spec.add_runtime_dependency('docker-api', '1.34.2')
  spec.add_runtime_dependency('keystore', '~> 0.2')
  spec.add_runtime_dependency('packer-config', '1.6.3')
  spec.add_runtime_dependency('rubyzip', '~> 1.3.0')
end
