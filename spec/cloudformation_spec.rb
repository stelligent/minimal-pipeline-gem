require './spec/spec_helper'

describe MinimalPipeline::Cloudformation do
  describe 'without AWS_REGION' do
    it 'requires AWS_REGION to be set' do
      expect {
        cloudformation = MinimalPipeline::Cloudformation.new
      }.to raise_error "You must set env variable AWS_REGION or region."
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

      expect {
        cloudformation = MinimalPipeline::Cloudformation.new
      }.to_not raise_error
    end

    it 'creates a CFN friendly parameter data structure' do
      cloudformation = MinimalPipeline::Cloudformation.new
      original_params = {
        'foo': 'bar',
        'beep': 'boop'
      }
      expected_params = [
        {:parameter_key=>:foo, :parameter_value=>"bar"},
        {:parameter_key=>:beep, :parameter_value=>"boop"}
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

    it 'creates a new stack if one does not already exist' do
      stack_parameters = {
        foo: 'bar'
      }

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new("foo", "bar"))
      expect(client).to receive(:wait_until).with(:stack_create_complete, {:stack_name=>"STACK-NAME"}).and_return(true)
      expect(client).to receive(:create_stack).with(stack_parameters)
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', stack_parameters)
    end

    it 'updates a new stack if it already exists' do
      stack_parameters = {
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
      expect(client).to receive(:wait_until).with(:stack_update_complete, {:stack_name=>"STACK-NAME"}).and_return(true)
      expect(client).to receive(:update_stack).with(stack_parameters)

      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', stack_parameters)
    end

    it 'to be idempotent if no changes are to be made' do
      stack_parameters = {
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
      expect(client).to_not receive(:wait_until).with(:stack_update_complete, {:stack_name=>"STACK-NAME"})
      expect(client).to receive(:update_stack).with(stack_parameters).and_raise(Aws::CloudFormation::Errors::ValidationError.new("foo", 'No updates are to be performed.'))

      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new
      cloudformation.deploy_stack('STACK-NAME', stack_parameters)
    end

    it 'allows template errors to bubble up as a real error' do
      stack_parameters = {
        foo: 'bar'
      }

      client = double(Aws::CloudFormation::Client)
      response = double(Aws::CloudFormation::Types::DescribeStacksOutput)

      expect(client).to receive(:describe_stacks).and_raise(Aws::CloudFormation::Errors::ValidationError.new("foo", "bar"))
      expect(client).to receive(:create_stack).with(stack_parameters).and_raise(Aws::CloudFormation::Errors::ValidationError.new("foo", 'Template error'))
      expect(Aws::CloudFormation::Client).to receive(:new).with(region: 'us-east-1').and_return(client)

      cloudformation = MinimalPipeline::Cloudformation.new

      expect {
        cloudformation.deploy_stack('STACK-NAME', stack_parameters)
      }.to raise_error
    end
  end
end
