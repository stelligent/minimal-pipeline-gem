require './spec/spec_helper'

# rubocop:disable Metrics/BlockLength, Metrics/LineLength
describe MinimalPipeline::Docker do
  it 'cleans up docker images' do
    image = double(Docker::Image)

    expect(Docker::Image).to receive(:get).with('foo').and_return(image)
    expect(image).to receive(:remove).with(force: true)

    docker = MinimalPipeline::Docker.new
    docker.clean_up_image('foo')
  end

  it 'builds a docker image' do
    expected_args = {
      'nocache' => 'true',
      'pull' => 'true',
      't' => 'foo',
      'dockerfile' => 'Dockerfile',
      'buildargs' => '{"NO_PROXY":"127.0.0.1,localhost,circleci-internal-outer-build-agent"}'
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo')
  end

  it 'passes proxy settings through' do
    ENV['HTTP_PROXY'] = 'foo:443'

    expected_args = {
      'nocache' => 'true',
      'pull' => 'true',
      't' => 'foo',
      'dockerfile' => 'Dockerfile',
      'buildargs' => '{"HTTP_PROXY":"foo:443","NO_PROXY":"127.0.0.1,localhost,circleci-internal-outer-build-agent"}'
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo')

    ENV.delete('HTTP_PROXY')
  end

  it 'supports custom build args' do
    passed_args = {
      'DEPLOYABLE_VERSION' => '1.0.0'
    }
    expected_args = {
      'nocache' => 'true',
      'pull' => 'true',
      't' => 'foo',
      'dockerfile' => 'Dockerfile',
      'buildargs' => '{"DEPLOYABLE_VERSION":"1.0.0","NO_PROXY":"127.0.0.1,localhost,circleci-internal-outer-build-agent"}'
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo', build_args: passed_args)
  end

  it 'pushes built images' do
    docker_path = `which docker`.chomp

    status = double(Object)
    expect(status).to receive(:exitstatus).and_return(0)
    expect(Open3).to receive(:capture3).with(docker_path, 'push', 'foo').and_return(['', '', status])

    docker = MinimalPipeline::Docker.new
    expect(docker).to receive(:clean_up_image)
    docker.push_docker_image('foo')
  end

  it 'outputs JSON build output lines as human readible text' do
    example_output = %q({"foo": "bar","stream": "baz"})

    expect($stdout).to receive(:puts).with('baz')

    docker = MinimalPipeline::Docker.new
    docker.build_output(example_output)
  end

  it 'detects bad JSON' do
    example_output = %q({"foo": "bar" "stream": "baz"})

    expect($stdout).to receive(:puts).with("Bad JSON parse\n")
    expect($stdout).to receive(:puts).with(example_output)

    docker = MinimalPipeline::Docker.new
    docker.build_output(example_output)
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/LineLength
