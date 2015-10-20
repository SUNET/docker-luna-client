#!/bin/bash -x

SAFENET=/usr/safenet/lunaclient

if [ ! -f "${SAFENET}/cert/client/${HOSTNAME}.pem" -o ! -f "${SAFENET}/cert/client/${HOSTNAME}Key.pem" ]; then
   vtl createCert -n ${HOSTNAME}
fi

for cert in `find ${SAFENET}/cert/server -name \*Cert.pem`; do
   hsm=`basename $cert Cert.pem`
   grep -q $hsm /etc/Chrystoki.conf || vtl addServer -n $hsm -c $cert
done

exec $*
