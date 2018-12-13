require './spec/spec_helper'

# rubocop:disable Metrics/BlockLength, Metrics/LineLength
describe MinimalPipeline::Packer do
  it 'executes a proper packer command' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    expected_command = 'packer -machine-readable build packer/test.json'
    expect(Open3).to receive(:popen2e).with(expected_command)

    packer.build_ami
  end

  it 'executes a proper packer command with variables' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    expected_command = 'packer -machine-readable build ' \
                       '-var \'source_ami=foo\' -var \'something=else\' '\
                        'packer/test.json'
    expect(Open3).to receive(:popen2e).with(expected_command)

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

    expect(packer.get_ami_id(example_output)).to eq(expected_ami_id)
  end

  it 'displays packer output in real-time' do
    packer = MinimalPipeline::Packer.new('packer/test.json')
    expect_any_instance_of(Process::Status).to receive(:success?).and_return(true)
    expect_any_instance_of(IO).to receive(:gets).once.and_return('Line of output')
    expect_any_instance_of(IO).to receive(:gets).once.and_return(nil)
    expect(STDOUT).to receive(:puts).with('Line of output')
    expect($stdout).to receive(:flush)
    expect(packer).to receive(:get_ami_id)
    packer.build_ami
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/LineLength
