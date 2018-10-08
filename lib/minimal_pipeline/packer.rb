# frozen_string_literal: true

require 'packer-config'

class MinimalPipeline
  # Here is an example of how to use this class to build AMIs from Packer YAML
  #
  # ```
  # # Pass in the path to the Packer JSON config file
  # packer = MinimalPipeline::Packer.new('path/to/packer.json')
  #
  # variables = {
  #   'foo' => 'bar',
  # }
  #
  # # Build the AMI and get the new AMI ID
  # new_ami_id = packer.build_ami(variables)
  # ```
  class Packer
    attr_accessor :config

    # Instaniate a Packer object
    #
    # @param packer_config [String] Path to the JSON packer config file
    def initialize(packer_config)
      @config = packer_config
    end

    # Parse the newly built AMI from a given packer command output
    #
    # @param output [String] The command output of a packer run
    # @return [String]
    def get_ami_id(output)
      return if output.nil? || output.empty?
      output.match(/AMIs were created:.+ (ami-.{17})/)[1]
    end

    # Build and execute a packer build command
    #
    # @param variables [Hash] Optional key value pairs of packer variables
    # @return [String]
    def build_ami(variables = {})
      variable_string = ''

      variables.each_pair do |key, value|
        variable_string += "-var '#{key}=#{value}' "
      end

      command = 'packer -machine-readable build '
      command += variable_string unless variable_string.empty?
      command += @config
      puts command if ENV['DEBUG']

      output = `#{command}`
      puts output if ENV['DEBUG']
      get_ami_id(output)
    end
  end
end
