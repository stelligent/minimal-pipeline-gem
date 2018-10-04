# frozen_string_literal: true

require 'aws-sdk'
require 'crossing'
require 'keystore'
require 'open3'
require 'docker'
require 'json'

# Top level namespace for automation pipeline classes
class MinimalPipeline
  # autoload libraries
  autoload(:Cloudformation, 'minimal_pipeline/cloudformation')
  autoload(:Crossing, 'minimal_pipeline/crossing')
  autoload(:Docker, 'minimal_pipeline/docker')
  autoload(:Keystore, 'minimal_pipeline/keystore')
  autoload(:Packer, 'minimal_pipeline/packer')
end
