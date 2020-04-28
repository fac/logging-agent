#!groovy

@Library('freeagent') _

freeagent(node: 'smartos', slack: [channel: '#ops-ci']) {
  stage('Install') {
    bundle.install("--path vendor")
  }

  stage('Test') {
    bundle.exec "rake"
  }

  stage("Gem Build") {
    bundle.exec "rake build"
  }

  if (env.BRANCH_NAME == "release-to-gemstash") {
    stage('Gem Release') {
      gemRelease(node: 'smartos', slack: [channel: '#ops-ci'])
    }
  }

  // WARNING: this includes a stage
  pruneRemoteBranches()
}
