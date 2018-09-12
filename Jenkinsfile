#!groovy

def nodes = ["smartos", "centos"]
def ruby_versions = ["system", "2.3.7", "2.4.1"]
def tasks = [:]

@Library('freeagent') _

freeagent(node: 'smartos', slack: [channel: '#ops-ci']) {
  parallel centos: {
    node('centos') {
      sh "chruby system"
      sh "bundle install"
      sh "bundle exec rake"
    }
  },
  smartos: {
    node('smartos') {
      sh "chruby system"
      sh "bundle install"
      sh "bundle exec rake"
    }
  }
}

