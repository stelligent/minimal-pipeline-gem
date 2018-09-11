[![CircleCI](https://circleci.com/gh/stelligent/minimal-pipeline-gem.svg?style=svg)](https://circleci.com/gh/stelligent/minimal-pipeline-gem)

# Minimal Pipeline Gem

> Helper gem to manage pipeline deploy tasks

A Simple gem to help orchestrate pipeline tasks in ruby.

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

## License

MIT

## Maintainers

* [@obaladeo](https://git.uscis.dhs.gov/obaladeo).
* [@jesseadams](https://git.uscis.dhs.gov/jesseadams).
