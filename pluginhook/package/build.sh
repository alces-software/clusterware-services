#!/bin/bash

package_name='pluginhook'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

curl -L "https://github.com/progrium/pluginhook/archive/7b91f7692d3ec494d4945f27d6b88864cd2f4bde.tar.gz" \
  -o /tmp/pluginhook-source.tar.gz
tar -C "/tmp" -xzf "/tmp/pluginhook-source.tar.gz"
rm "/tmp/pluginhook-source.tar.gz"

if command -v yum > /dev/null; then
  sudo yum install -y -e0 golang
elif command -v apt-get > /dev/null; then
  sudo apt-get -y -q install golang
fi

pushd /tmp/pluginhook-7b91f7692d3ec494d4945f27d6b88864cd2f4bde > /dev/null

mkdir -p build
export GOPATH=$(pwd)/build
go get "golang.org/x/crypto/ssh/terminal" &> /dev/null
go build -o pluginhook
mkdir -p "${temp_dir}"/data/opt/pluginhook/bin
cp pluginhook "${temp_dir}"/data/opt/pluginhook/bin

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
rm -rf /tmp/pluginhook*
