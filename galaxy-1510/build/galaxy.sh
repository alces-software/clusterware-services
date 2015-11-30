#!/bin/bash
curl -L "https://github.com/galaxyproject/galaxy/archive/release_15.10.zip" -o /tmp/release_15.10.zip
unzip -d /tmp /tmp/release_15.10.zip >/dev/null

GALAXYDIR="${SERVICEDIR}/galaxy"
mv /tmp/galaxy-release_15.10 "${GALAXYDIR}"
install -Dm640 build/galaxy.ini "${GALAXYDIR}"/config/galaxy.ini
chown galaxy "${GALAXYDIR}"/config/galaxy.ini

pushd "${GALAXYDIR}"
cp config/tool_conf.xml.sample config/tool_conf.xml
mkdir shed-tool-deps
# run in background
./run.sh &
GALAXYPID=$!
if [ "$GALAXYPID" ]; then
    # wait until it's listening on port
    while ps $GALAXYPID >/dev/null && ! ss -ln | grep -q 'LISTEN.*:6414 '; do
        sleep 5
    done
    curl -X POST --data 'create_user_button=Submit&email=admin%40alces.network&password=changeme&confirm=changeme&username=galaxy-admin' http://localhost:6414/user/create &>/dev/null
    # kill background process
    kill $GALAXYPID
    pkill -f "paster.py serve config/galaxy.ini"
fi

sed -i -e 's,^#database_connection = postgresql,database_connection = postgresql,g' -e 's,^database_connection = sqlite,#database_connection = sqlite,g' config/galaxy.ini
./run.sh &>/dev/null || true
popd
