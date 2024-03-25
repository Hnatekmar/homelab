#!/bin/bash

BUTANE_CONFIG=$1


if [ ! -f coreos.iso ]; then
  INSTALL_ISO=$(coreos-installer download -f iso -p metal)
  mv $INSTALL_ISO coreos.iso
fi

echo "Converting butane to ignition"
docker run -i --rm quay.io/coreos/butane:release < $BUTANE_CONFIG > ignition.json
echo "Embedding ignition to iso"
coreos-installer iso ignition embed -i ignition.json -f coreos.iso
