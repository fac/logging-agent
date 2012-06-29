README
======

Steps to build a gem:

1. ensure the gemspec correctly reflects any added or removed files.

2. bump the version in lib/log_agent/version.rb according to semantic versioning

3. commit and push to github

4. gem build log_agent.gemspec which will kick out the gem file

5. copy this into puppet-config:modules/logging/files/log_agent.gem