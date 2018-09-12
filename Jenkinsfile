#!groovy

def nodes = ["smartos", "centos"]
def ruby_versions = ["system", "2.3.7", "2.4.1"]

@Library('freeagent') _

def build_process(node_spec, ruby_spec) {
  { ->
    node(node_spec) {
      checkout scm
      sh "chruby-exec $ruby_spec -- bundle install --path .bundle"
      sh "chruby-exec $ruby_spec -- bundle exec rake"
    }
  }
}

freeagent(node: 'smartos', slack: [channel: '#ops-ci']) {
  def builds = [:]
  for(i=0;i<nodes.size(); i++) {
    for(j=0;j<ruby_versions.size(); j++) {
      n = nodes[i]
      r = ruby_versions[j]

      builds["${n}_${r}"] = build_process(n, r)
    }
  }
  parallel builds
}

