require 'rspec'
require 'minimal_pipeline'
require 'simplecov'

SimpleCov.start do
  add_filter %r{^/spec/}
end

ENV['NO_PROXY'] = '127.0.0.1,localhost,circleci-internal-outer-build-agent'
ENV.delete('http_proxy')
ENV.delete('https_proxy')
ENV.delete('no_proxy')

RSpec::Expectations.configuration.on_potential_false_positives = :nothing
