# frozen_string_literal: true

require 'aws-sdk'

class MinimalPipeline
  # Here is an example of how to use this class to deploy CloudFormation Stacks.
  #
  # ```
  # cloudformation = MinimalPipeline::Cloudformation.new
  #
  # cloudformation_parameters = {
  #   'Vpc' => 'vpc-123456',
  #   'AsgSubnets' => %w[sg-one sg-two sg-three],
  #   'ElbSecurityGroup' => 'sg-123456',
  #   'CertName' => 'example'
  # }
  #
  # stack_parameters = {
  #   stack_name: stack_name,
  #   template_body: File.read('provisioning/elb.json'),
  #   capabilities: ['CAPABILITY_IAM'],
  #   parameters: cloudformation.params(cloudformation_parameters)
  # }
  #
  # cloudformation.deploy_stack('EXAMPLE_ELB', stack_parameters)
  # name = cloudformation.stack_output(stack_name, 'LoadBalancerName')
  # ```
  #
  # You will need the following environment variables to be present:
  # * `AWS_REGION` or `region`
  class Cloudformation
    # Instance of `Aws::CloudFormation::Client`
    attr_reader(:client)
    attr_accessor(:wait_max_attempts)
    attr_accessor(:wait_delay)

    # Sets up `Aws::CloudFormation::Client`
    # Requires environment variable `AWS_REGION` or `region` to be set.
    #
    # @param wait_max_attempts [Fixnum] Number of attempts to wait until all
    # stack create or update is complete.
    # @param wait_delay [Fixnum] The sleep interval for checking the status of
    # a stack's status
    def initialize(wait_max_attempts = 120, wait_delay = 30)
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?

      region = ENV['AWS_REGION'] || ENV['region']
      @client = Aws::CloudFormation::Client.new(region: region)
      @wait_max_attempts = wait_max_attempts
      @wait_delay = wait_delay
    end

    # Converts a parameter Hash into a CloudFormation friendly structure
    #
    # @param parameters [Hash] Key value pair of parameters for a CFN stack.
    # @return [Hash] CloudFormation friendly data structure of parameter
    def params(parameters)
      parameter_list = []
      parameters.each do |k, v|
        parameter_list.push(parameter_key: k, parameter_value: v)
      end
      parameter_list
    end

    # Retrieves the CloudFormation stack output of a single value
    #
    # @param stack [String] The name of the CloudFormation stack
    # @param output [String] The name of the output to fetch the value of
    # @return [String] The value of the output for the CloudFormation stack
    def stack_output(stack, output)
      resp = @client.describe_stacks(stack_name: stack)

      raise "#{stack.upcase} stack does not exist!" if resp.stacks.empty?

      resp.stacks.first.outputs.each do |stack_output|
        zero_output = stack_output.output_key.casecmp(output).zero?
        return stack_output.output_value if zero_output
      end

      raise "#{stack.upcase} stack does not have a(n) '#{output}' output!"
    end

    # Creates or Updates a CloudFormation stack. Checks to see if the stack
    # already exists and takes the appropriate action. Pauses until a final
    # stack state is reached.

    # @param stack_name [String] The name of the CloudFormation stack
    # @param stack_parameters [Hash] Parameters to be passed into the stack
    def deploy_stack(stack_name, stack_parameters)
      wait_options = {
        max_attempts: @wait_max_attempts,
        delay: @wait_delay
      }

      unless @client.describe_stacks(stack_name: stack_name).stacks.empty?
        puts 'Updating the existing stack' if ENV['DEBUG']
        @client.update_stack(stack_parameters)
        @client.wait_until(:stack_update_complete, { stack_name: stack_name },
                           wait_options)
      end
    rescue Aws::CloudFormation::Errors::ValidationError => error
      if error.to_s.include? 'No updates are to be performed.'
        puts 'Nothing to do.' if ENV['DEBUG']
      elsif error.to_s.include? 'Template error'
        raise error
      else
        puts 'Creating a new stack' if ENV['DEBUG']
        @client.create_stack(stack_parameters)
        @client.wait_until(:stack_create_complete, { stack_name: stack_name },
                           wait_options)
      end
    end
  end
end
