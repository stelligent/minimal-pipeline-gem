require './spec/spec_helper'

# rubocop:disable Metrics/BlockLength
describe MinimalPipeline::Packer do
  it 'executes a proper packer command' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    expected_command = 'packer -machine-readable build packer/test.json'
    expect_any_instance_of(Kernel).to receive(:`).with(expected_command)

    packer.build_ami
  end

  it 'executes a proper packer command with variables' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    expected_command = 'packer -machine-readable build ' \
                       '-var \'source_ami=foo\' -var \'something=else\' '\
                        'packer/test.json'
    expect_any_instance_of(Kernel).to receive(:`).with(expected_command)

    variables = {
      'source_ami' => 'foo',
      'something' => 'else'
    }

    packer.build_ami(variables)
  end

  it 'successfully parses the built AMI from the packer output' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    example_output = File.read('spec/packer/example_packer_output.txt')
    expected_ami_id = 'ami-0e9cdb3c46fcd5015'

    expect_any_instance_of(Kernel).to receive(:`).and_return(example_output)
    new_ami_id = packer.build_ami

    expect(new_ami_id).to eq(expected_ami_id)
  end
end
# rubocop:enable Metrics/BlockLength
