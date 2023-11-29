#!/usr/bin/env sh
set -eu

echo "~~~ update RubyGems and Bundler"
if [ "${RUBY_VERSION:-}" = "2.6.10" ]; then
  gem install bundler -v "~> 2"
  gem update --system >/dev/null
else
  gem install bundler -v 2.3.27
  gem update --system 3.2.3 >/dev/null
fi

echo "~~~ bundle install"
bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2
