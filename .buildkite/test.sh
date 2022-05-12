#!/usr/bin/env sh
set -eu

echo "~~~ bundle install"
bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2

until curl -s -o /dev/null "$DB_HOST:3306"; do
  sleep 5
  echo "Waiting for MySQL"
done

mkdir -p tmp
mkdir -p log

bin/rspec \
  --format RspecJunitFormatter \
  --out "tmp/rspec-junit-$BUILDKITE_JOB_ID.xml" \
  --format documentation
