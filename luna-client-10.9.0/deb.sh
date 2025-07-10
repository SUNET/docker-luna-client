#!/usr/bin/bash

set -e

file="$1"
baseurl="$2"
shasum="$3"

if [ "${file}x" == "x" ]; then
	echo "A file must be specified as \$1"
	exit 1
fi

if [ "${baseurl}x" == "x" ]; then
	echo "A baseurl must be specified as \$2"
	exit 1
fi

if [ "${shasum}x" == "x" ]; then
	echo "A shasum must be specified as \$3"
	exit 1
fi

tempdir=$(mktemp -d)

curl -O --output-dir "${tempdir}" "${baseurl}/${file}"
echo "${shasum} ${tempdir}/${file}" | sha256sum -c

if [ -f /etc/Chrystoki.conf ]; then
	cp /etc/Chrystoki.conf "/etc/Chrystoki.conf-$(date +%Y-%m-%d-%H%M)"
fi

tar -xvf "${tempdir}/${file}" -C "${tempdir}" --strip-components=1

# Accept license
sed -i '/display_license /d' "${tempdir}/64/install.sh"

# We already backuped the config don't bother to ask
sed -i 's/save_conf_file() {/&\nCONF_FILE_DIR="\/etc"\nreturn 0/' "${tempdir}/64/install.sh"

"${tempdir}/64/install.sh" -p network

rm -rf "${tempdir}"
