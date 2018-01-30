#!/bin/bash

package_name='websockify'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"


curl -L "https://github.com/kanaka/websockify/archive/v0.7.0.tar.gz" -o /tmp/websockify-source.tar.gz
tar -C /tmp -xzf "/tmp/websockify-source.tar.gz"
pushd /tmp/websockify-0* > /dev/null
mkdir -p "${temp_dir}/data/opt/websockify/lib"
cat <<\EOF > "${temp_dir}/data/opt/websockify/websockify"
#!/bin/bash
pushd $(dirname "$BASH_SOURCE")/lib > /dev/null
exec ./run "$@"
EOF
chmod 755 "${temp_dir}/data/opt/websockify/websockify"
cp -R websockify run README.md LICENSE.txt docs "${temp_dir}/data/opt/websockify/lib"
popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
