require 'rspec'
require 'minimal_pipeline'
require 'simplecov'

SimpleCov.start

ENV['NO_PROXY'] = '127.0.0.1,localhost,circleci-internal-outer-build-agent' unless ENV.key?('NO_PROXY')
