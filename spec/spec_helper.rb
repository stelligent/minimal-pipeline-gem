require 'rspec'
require 'minimal_pipeline'
require 'simplecov'

SimpleCov.start do
  add_filter %r{^/spec/}
end

ENV['NO_PROXY'] = '127.0.0.1,localhost,circleci-internal-outer-build-agent' unless ENV.key?('NO_PROXY')
