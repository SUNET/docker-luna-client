#!/bin/sh

set -e
set -x

. /opt/eduid/bin/activate

log_dir=${log_dir-'/var/log/eduid'}
var_dir=${var_dir-'/var/lib/softhsm'}
logfile=${logfile-"${log_dir}/${eduid_name}.log"}
p11_module=${p11_module-'/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'}

PYELEVEN_ARGS=${PYELEVEN_ARGS-'-w2 --user eduid --group softhsm --reload'}
PYELEVEN_PORT=${PYELEVEN_PORT-'8000'}
PKCS11PIN=${PKCS11PIN-'1234'}
PKCS11SOPIN=${PKCS11SOPIN-'123456'}

if [ ! -d "${var_dir}/tokens" ]; then
    echo "$0: Initializing SoftHSM token"
    mkdir /var/lib/softhsm/tokens
    softhsm2-util --init-token --slot 0 --label "py11softhsm" --pin "${PKCS11PIN}" --so-pin "${PKCS11SOPIN}"
    if [ -f "${p11softhsm_init_rsa_key}" ]; then
	echo "$0: Loading private RSA key from ${p11softhsm_init_rsa_key}"
	tmpder="/dev/shm/py11softhsm_privkey.der"
	touch ${tmpder}
	chmod 600 ${tmpder}
	openssl rsa -inform PEM -outform DER -in "${p11softhsm_init_rsa_key}" -out ${tmpder}
	pkcs11-tool --module "${p11_module}" --id 1 --label eduid --login --pin "${PKCS11PIN}" \
		    -y privkey -w ${tmpder}
	rm ${tmpder}
    fi
fi

chown -R eduid: "${log_dir}"
chown -R eduid:softhsm "${var_dir}" /etc/softhsm
find "${var_dir}" -type d -print0 | xargs -0 chmod 750
find "${var_dir}" -type f -print0 | xargs -0 chmod 640

#touch "${logfile}"
#chgrp eduid "${logfile}"
#chmod 660 "${logfile}"

if [ "x$ENABLE_PKCS11_SPY" != "x" ]; then
    echo "$0: Enabling pkcs11-spy since \$ENABLE_PKCS11_SPY is set"
    PKCS11SPY="${p11_module}"
    p11_module='/usr/lib/x86_64-linux-gnu/pkcs11-spy.so'
    export PKCS11SPY
fi

cat>/config.py<<EOF
DEBUG = True
PKCS11MODULE = "${p11_module}"
PKCS11PIN = "${PKCS11PIN}"
EOF

echo "$0: Starting Gunicorn app pyeleven:app"
exec gunicorn -b "0.0.0.0:${PYELEVEN_PORT}" ${PYELEVEN_ARGS} pyeleven:app
