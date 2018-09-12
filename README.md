README
======

This process resides on all servers scraping logs from various sources and pushes them to outputs.

WARNING: Be careful when merging and version bumping - as soon as Jenkins sees a new version on the `master` branch, it will merge and push and Puppet will then install this version automatically.

If you push a "pre" version to the `master` branch then this shouldn't get automatically installed to servers by puppet, but will be manually installable using the RubyGems `--pre` flag.
