#!/usr/bin/env sh
set -eu

echo "~~~ Waiting for MySQL"
retries=5

until ruby -rsocket -e 'Socket.tcp(ENV["DB_HOST"], 3306).close' 2>/dev/null; do
  retries="$(("$retries" - 1))"

  if [ "$retries" -eq 0 ]; then
    echo "Failed to reach MySQL" >&2
    exit 1
  fi

  sleep 5
  echo "Waiting for MySQL ($retries retries left)"
done

echo "+++ :rspec: Running specs"
mkdir -p tmp
mkdir -p log

bin/rspec \
  --format RspecJunitFormatter \
  --out "tmp/rspec-junit-$BUILDKITE_JOB_ID.xml" \
  --format documentation
