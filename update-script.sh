#/usr/bin/env bash

MUSER=${MUSER:-admin}
MHOST=${MHOST:-192.168.88.1}

SCRIPT_FILE="mikrotik"
DOMAIN_LIST="domains.txt"

if [[ ! -f ${SCRIPT_FILE} ]]; then
  echo "Error: File not found at ${SCRIPT_FILE}"
  exit 1
fi

# Collect script source with escape sequences
SCRIPT_SOURCE=
while IFS= read -r line || [ -n "$line" ]; do
  line=$(sed 's/\\/\\\\/g' <<< ${line})
  line=$(sed 's/\"/\\"/g' <<< ${line})
  line=$(sed 's/\$/\\$/g' <<< ${line})
  SCRIPT_SOURCE+="${line}\r\n"
done < "$SCRIPT_FILE"

# Remote old script and create new.
ssh -T ${MUSER}@${MHOST} << EOF
:if ([:len [/system/script find name=${SCRIPT_FILE}]] > 0) do={\
  :put "Script '${SCRIPT_FILE}' already exists. Remove it.";\
  /system/script remove ${SCRIPT_FILE}\
}
:put "Create a new script with name '${SCRIPT_FILE}'"
/system/script add name=${SCRIPT_FILE} source="${SCRIPT_SOURCE}"
/system/script run ${SCRIPT_FILE}
EOF

# Copy domains list
if [[ -f ${DOMAIN_LIST} ]]; then
  echo "Copy ${DOMAIN_LIST} to ${MHOST}"
  scp ${PWD}/${DOMAIN_LIST} ${MUSER}@${MHOST}:/
fi
