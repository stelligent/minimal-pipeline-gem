require 'rspec'
require 'minimal_pipeline'
require 'simplecov'

SimpleCov.start do
  add_filter %r{^/spec/}
end

unless ENV.key?('NO_PROXY')
  ENV['NO_PROXY'] = '127.0.0.1,localhost,circleci-internal-outer-build-agent'
end

RSpec::Expectations.configuration.on_potential_false_positives = :nothing
