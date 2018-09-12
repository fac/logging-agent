#!groovy

def nodes = ["smartos", "centos"]
def ruby_versions = ["system", "2.3.7", "2.4.1"]
def tasks = [:]

@Library('freeagent') _

freeagent(node: 'smartos', slack: [channel: '#ops-ci']) {
  parallel centos237: {
    node('centos') {
      checkout scm
      sh "chruby 2.3.7"
      sh "bundle install"
      sh "bundle exec rake"
    }
  },
  smartos237: {
    node('smartos') {
      checkout scm
      sh "chruby 2.3.7"
      sh "bundle install"
      sh "bundle exec rake"
    }
  }
}

