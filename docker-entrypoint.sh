#!/usr/bin/env sh
set -eu

# https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
group() {
  echo "::group::${1}"
}

endgroup() {
  echo "::endgroup::"
}

group "update RubyGems and Bundler"

# latest supported versions for Ruby 2.x
gem install bundler -v "~> 2.4.22"
gem update --system 3.4.22 >/dev/null

endgroup

group "bundle install"

bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2

endgroup
