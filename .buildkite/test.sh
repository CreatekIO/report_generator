#!/usr/bin/env sh
set -eu

gem install bundler -v 2.3.27
gem update --system 3.2.3

echo "~~~ bundle install"
bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2

echo "~~~ Waiting for MySQL"
until curl -s -o /dev/null "$DB_HOST:3306"; do
  sleep 5
  echo "Waiting for MySQL"
done

echo "+++ :rspec: Running specs"
mkdir -p tmp
mkdir -p log

bin/rspec \
  --format RspecJunitFormatter \
  --out "tmp/rspec-junit-$BUILDKITE_JOB_ID.xml" \
  --format documentation
