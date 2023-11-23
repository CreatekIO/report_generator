#!/usr/bin/env sh
set -eu

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
