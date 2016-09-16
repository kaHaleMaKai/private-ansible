#!/bin/bash
set -euo pipefail

principal="$1"
realm="$2"
password="$3"
path="$4"
kerberos_version="${5}"
encryption="${6}"

( [[ -e "$path" ]] \
  && echo -en "ok" ) \
|| (ktutil <<- END_OF_KEYTAB >/dev/null 2>&1 ||
add_entry -password -p ${principal}@${realm} -k ${kerberos_version} -e ${encryption}
${password}
wkt ${path}
END_OF_KEYTAB
[[ -e "$path" ]] && echo  -en "changed" || echo " -en failed")
