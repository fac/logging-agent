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

  if (env.BRANCH_NAME == "master") {
    stage('Gem Release') {
      gemRelease(args)
    }
  }

  // WARNING: this includes a stage
  pruneRemoteBranches()
}
