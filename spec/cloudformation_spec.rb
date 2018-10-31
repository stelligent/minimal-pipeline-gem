require './spec/spec_helper'

# rubocop:disable Metrics/BlockLength, Metrics/LineLength
describe MinimalPipeline::Cloudformation do
  describe 'without AWS_REGION' do
    it 'requires AWS_REGION to be set' do
      ENV.delete('AWS_REGION')

      expect do
        MinimalPipeline::Cloudformation.new
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

    it 'does not throw an error if AWS_REGION is set' do
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1')

      expect do
        MinimalPipeline::Cloudformation.new
      end.to_not raise_error
    end

    it 'creates a CFN friendly parameter data structure' do
      cloudformation = MinimalPipeline::Cloudformation.new
      original_params = {
        'foo': 'bar',
        'beep': 'boop'
      }
      expected_params = [
        { parameter_key: :foo, parameter_value: 'bar' },
        { parameter_key: :beep, parameter_value: 'boop' }
      ]

      resulting_params = cloudformation.params(original_params)

      expect(resulting_params).to eq(expected_params)
    end

    it 'grabs the requested stack output' do
      outputs = [
        Aws::CloudFormation::Types::Output.new(
          description: 'Description',
          export_name: 'Export Name',
          output_key: 'OutputName',
          output_value: 'Foo'
        )
      ]

      stacks = [
        Aws::CloudFormation::Types::Stack.new(outputs: outputs)
      ]

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).with(stack_name: 'STACK-NAME').and_return(response)
      expect(response).to receive(:stacks).and_return(stacks).at_least(:once)
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      output = cloudformation.stack_output('STACK-NAME', 'OutputName')

      expect(output).to eq 'Foo'
    end

    it 'throws an error if the expected stack output does not exist' do
      outputs = [
        Aws::CloudFormation::Types::Output.new(
          description: 'Description',
          export_name: 'Export Name',
          output_key: 'OutputName',
          output_value: 'Foo'
        )
      ]

      stacks = [
        Aws::CloudFormation::Types::Stack.new(outputs: outputs)
      ]

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).with(stack_name: 'STACK-NAME').and_return(response)
      expect(response).to receive(:stacks).and_return(stacks).at_least(:once)
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      expect do
        cloudformation.stack_output('STACK-NAME', 'AnotherOutputName')
      end.to raise_error
    end

    it 'creates a new stack if one does not already exist' do
      expected_stack_parameters = {
        capabilities: ['CAPABILITY_IAM'],
        parameters: [
          {
            parameter_key: :foo,
            parameter_value: 'bar'
          }
        ],
        stack_name: 'STACK-NAME',
        template_body: '---'
      }

      cloudformation_parameters = {
        foo: 'bar'
      }

      wait_options = {
        delay: 30,
        max_attempts: 120
      }

      client = double(Aws::CloudFormation::Client)

      expect(client).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new('foo', 'bar'))
      expect(client).to receive(:wait_until).with(:stack_create_complete, { stack_name: 'STACK-NAME' }, wait_options).and_return(true)
      expect(client).to receive(:create_stack).with(expected_stack_parameters)
      expect(File).to receive(:read).with('foo.yaml').and_return('---')
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', cloudformation_parameters, 'foo.yaml')
    end

    it 'updates a new stack if it already exists' do
      expected_stack_parameters = {
        capabilities: ['CAPABILITY_IAM'],
        parameters: [
          {
            parameter_key: :foo,
            parameter_value: 'bar'
          }
        ],
        stack_name: 'STACK-NAME',
        template_body: '---'
      }

      cloudformation_parameters = {
        foo: 'bar'
      }

      wait_options = {
        delay: 30,
        max_attempts: 120
      }

      outputs = [
        Aws::CloudFormation::Types::Output.new(
          description: 'Description',
          export_name: 'Export Name',
          output_key: 'OutputName',
          output_value: 'Foo'
        )
      ]

      stacks = [
        Aws::CloudFormation::Types::Stack.new(outputs: outputs)
      ]

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).with(stack_name: 'STACK-NAME').and_return(response)
      expect(response).to receive(:stacks).and_return(stacks).at_least(:once)
      expect(client).to receive(:wait_until).with(:stack_update_complete, { stack_name: 'STACK-NAME' }, wait_options).and_return(true)
      expect(client).to receive(:update_stack).with(expected_stack_parameters)
      expect(File).to receive(:read).with('foo.yaml').and_return('---')

      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', cloudformation_parameters, 'foo.yaml')
    end

    it 'is idempotent if no changes are to be made' do
      expected_stack_parameters = {
        capabilities: ['CAPABILITY_IAM'],
        parameters: [
          {
            parameter_key: :foo,
            parameter_value: 'bar'
          }
        ],
        stack_name: 'STACK-NAME',
        template_body: '---'
      }

      cloudformation_parameters = {
        foo: 'bar'
      }

      outputs = [
        Aws::CloudFormation::Types::Output.new(
          description: 'Description',
          export_name: 'Export Name',
          output_key: 'OutputName',
          output_value: 'Foo'
        )
      ]

      stacks = [
        Aws::CloudFormation::Types::Stack.new(outputs: outputs)
      ]

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).with(stack_name: 'STACK-NAME').and_return(response)
      expect(response).to receive(:stacks).and_return(stacks).at_least(:once)
      expect(client).to_not receive(:wait_until).with(:stack_update_complete, stack_name: 'STACK-NAME')
      expect(client).to receive(:update_stack).with(expected_stack_parameters).and_raise(Aws::CloudFormation::Errors::ValidationError.new('foo', 'No updates are to be performed.'))
      expect(File).to receive(:read).with('foo.yaml').and_return('---')

      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', cloudformation_parameters, 'foo.yaml')
    end

    it 'allows template errors to bubble up as a real error' do
      parameters = {
        foo: 'bar'
      }

      client = double(Aws::CloudFormation::Client)
      error = Aws::CloudFormation::Errors::ValidationError.new('foo', 'Template error')

      expect(client).to receive(:describe_stacks).and_raise(error)
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)
      expect(File).to receive(:read).with('foo.yaml')

      cloudformation = MinimalPipeline::Cloudformation.new

      expect do
        cloudformation.deploy_stack('STACK-NAME', parameters, 'foo.yaml')
      end.to raise_error(error)
    end

    it 'detects that a stack exists' do
      stacks = [
        Aws::CloudFormation::Types::Stack.new(stack_name: 'foo')
      ]

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).with(stack_name: 'foo').and_return(response)
      expect(response).to receive(:stacks).and_return(stacks).at_least(:once)

      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      response = cloudformation.stack_exists?('foo')
      expect(response).to be true
    end

    it 'detects that a stack does not exist' do
      client = double(Aws::CloudFormation::Client)
      error = Aws::CloudFormation::Errors::ValidationError.new('foo', 'Stack with id foo does not exist')

      expect(client).to receive(:describe_stacks).and_raise(error)
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      response = cloudformation.stack_exists?('foo')
      expect(response).to_not be true
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/LineLength
