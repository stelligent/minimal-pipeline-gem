[![CircleCI](https://circleci.com/gh/stelligent/minimal-pipeline-gem.svg?style=svg)](https://circleci.com/gh/stelligent/minimal-pipeline-gem)

# Minimal Pipeline Gem

> Helper gem to manage pipeline deploy tasks

A Simple gem to help orchestrate pipeline tasks in ruby. It currently supports deploying containers to ECS via CloudFormation.

## Tools Used
* Docker
* CloudFormation
* https://github.com/stelligent/crossing - Encrypt files and store them in S3
* https://github.com/stelligent/keystore - Encrypted key value store on top of DynamoDB

## Install

> Clone source repo

```sh
$ git clone git@github.com:stelligent/minimal-pipeline-gem.git
$ cd minimal-pipeline-gem
# Install
$ gem build minimal_pipeline.gemspec
$ gem install ./minimal_pipeline-VERSION.gem
```

## Documentation

Full documentation is available at https://stelligent.github.io/minimal-pipeline-gem/.

## Contributing

1. Checkout the code and run bundler: `bundle install`
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Run rubocop: `bundle exec rubocop`
5. Fix violations, if any
6. Run unit tests: `bundle exec rspec`
7. Ensure tests pass and 100% test coverage in maintained
8. Commit changes, push, and open a pull request with a detailed description.

## License

MIT

## Maintainers

* [@mayoralade](https://github.com/mayoralade).
* [@jesseadams](https://github.com/jesseadams).
