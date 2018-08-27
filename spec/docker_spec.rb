require 'minimal_pipeline'
require 'rspec'

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
      "nocache"=>"true",
      "pull"=>"true",
      "t"=>"foo",
      "buildargs"=>"{}"
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo')
  end

  it 'passes proxy settings through' do
    ENV['HTTP_PROXY'] = 'foo:443'

    expected_args = {
      "nocache"=>"true",
      "pull"=>"true",
      "t"=>"foo",
      "buildargs"=>"{\"HTTP_PROXY\":\"foo:443\"}"
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo')

    ENV.delete('HTTP_PROXY')
  end

  it 'supports custom build args' do
    passed_args = {
      "DEPLOYABLE_VERSION" => "1.0.0"
    }
    expected_args = {
      "nocache"=>"true",
      "pull"=>"true",
      "t"=>"foo",
      "buildargs"=>"{\"DEPLOYABLE_VERSION\":\"1.0.0\"}"
    }
    expect(Docker::Image).to receive(:build_from_dir).with('.', expected_args)

    docker = MinimalPipeline::Docker.new
    docker.build_docker_image('foo', build_args: passed_args)
  end

  it 'pushes built images' do
    status = double(Object)
    expect(status).to receive(:exitstatus).and_return(0)
    expect(Open3).to receive(:capture3).with('/usr/local/bin/docker', 'push', 'foo').and_return(['', '', status])

    docker = MinimalPipeline::Docker.new
    expect(docker).to receive(:clean_up_image)
    expect(docker).to receive(:ecr_login)
    docker.push_docker_image('foo')
  end
end
