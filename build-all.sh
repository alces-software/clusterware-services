#!/bin/bash

build_log_file="$(pwd)/build.log.$(date +%Y%m%d-%H%M%S)"
echo "Logging to ${build_log_file}"

for builder in `find -path '**/package/build.sh'`; do
  pushd `dirname $builder` > /dev/null
	  echo "$builder"
    ./build.sh 2>&1 >> "$build_log_file"
  popd > /dev/null
done

echo "Done."
