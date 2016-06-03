#!/bin/bash

SAFENET=/usr/safenet/lunaclient

cat>/etc/Chrystoki.conf<<EOF
Chrystoki2 = {
   LibUNIX = /usr/lib/libCryptoki2.so;
   LibUNIX64 = /usr/lib/libCryptoki2_64.so;
}

Luna = {
  DefaultTimeOut = 500000;
  PEDTimeout1 = 100000;
   PEDTimeout2 = 200000;
  PEDTimeout3 = 10000;
  KeypairGenTimeOut = 2700000;
  CloningCommandTimeOut = 300000;
  CommandTimeOutPedSet = 720000;
}

CardReader = {
  RemoteCommand = 1;
}

Misc = {
  PE1746Enabled = 0;
   ToolsDir = /usr/safenet/lunaclient/bin;
}
LunaSA Client = {
   ReceiveTimeout = 20000;
   SSLConfigFile = /usr/safenet/lunaclient/bin/openssl.cnf;
   ClientPrivKeyFile = /usr/safenet/lunaclient/cert/client/${HOSTNAME}Key.pem;
   ClientCertFile = /usr/safenet/lunaclient/cert/client/${HOSTNAME}.pem;
   ServerCAFile = /tmp/CAFile.pem;
   NetClient = 1;
EOF
N=0
rm -f /tmp/CAFile.pem
for cert in `find ${SAFENET}/cert/server -name \*Cert.pem`; do
   hsm=`basename $cert Cert.pem`
   NN=`printf "%02d" $N`
cat>>/etc/Chrystoki.conf<<EOF
   ServerName${NN} = ${hsm};
   ServerPort${NN} = 1792;
   ServerHtl${NN} = 0;
EOF
   N=`expr ${N} + 1`
   cat $cert >> /tmp/CAFile.pem
done
cat>>/etc/Chrystoki.conf<<EOF
}
EOF

export PATH=/usr/safenet/lunaclient/bin:$PATH

if [ ! -f "${SAFENET}/cert/client/${HOSTNAME}.pem" -o ! -f "${SAFENET}/cert/client/${HOSTNAME}Key.pem" ]; then
   vtl createCert -n ${HOSTNAME}
fi

if [ "x${PYELEVEN_ARGS}" = "x" ]; then
   PYELEVEN_ARGS="-w5"
fi

if [ "x${PYELEVEN_PORT}" = "x" ]; then
   PYELEVEN_PORT="8000"
fi

if [ "x${HTLC_ENABLED}" = "xyes" -o "x${HTLC_ENABLED}" = "x1" ]; then
   service htlc_service start
fi

if [ $# -eq 0 ]; then
   cat>/config.py<<EOF
DEBUG = True
PKCS11MODULE = "/usr/safenet/lunaclient/lib/libCryptoki2_64.so"
PKCS11PIN = "${PKCS11PIN}"
EOF
   exec gunicorn -b "0.0.0.0:${PYELEVEN_PORT}" "${PYELEVEN_ARGS}" pyeleven:app
else
   cd /tmp
   exec $*
fi
