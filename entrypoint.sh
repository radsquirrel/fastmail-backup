#!/bin/sh
set -eu

FM_USERNAME="${FM_USERNAME:-}"
FM_PASSWORD="${FM_PASSWORD:-}"

# validate that none of the required environment variables are empty
if [ -z "${FM_USERNAME}" ] || [ -z "${FM_PASSWORD}" ]
then
  echo "ERROR: Missing one or more of the following variables"
  echo "  FM_USERNAME=${FM_USERNAME}"
  echo "  FM_PASSWORD=$(if [ -n "${FM_PASSWORD}" ]; then printf "<value reddacted but present>";fi)"
  exit 1
fi

mkdir -p /config

cat > /config/mbsyncrc <<EOF
IMAPAccount fastmail
Host imap.fastmail.com
User ${FM_USERNAME}
Pass ${FM_PASSWORD}
SSLType IMAPS

IMAPStore fastmail-remote
Account fastmail

MaildirStore fastmail-local
SubFolders Verbatim
Path /data/mail/
Inbox /data/mail/Inbox

Channel fastmail
Master :fastmail-remote:
Slave :fastmail-local:
Patterns *
Create Slave
Sync Pull
SyncState *
EOF

cat > /config/vdirsyncer <<EOF
[general]
status_path = "/data"

[storage cal_remote]
type = "caldav"
read_only = true
url = "https://caldav.fastmail.com/"
username = "${FM_USERNAME}"
password = "${FM_PASSWORD}"

[storage cal_local]
type = "filesystem"
path = "/data/calendars/"
fileext = ".ics"

[pair calendars]
a = "cal_remote"
b = "cal_local"
collections = ["from a"]

[storage card_remote]
type = "carddav"
read_only = true
url = "https://carddav.fastmail.com/"
username = "${FM_USERNAME}"
password = "${FM_PASSWORD}"

[storage card_local]
type = "filesystem"
path = "/data/contacts/"
fileext = ".vcf"

[pair cards]
a = "card_remote"
b = "card_local"
collections = ["from a"]
EOF

echo -n \
'0 0,12 * * * \
    sleep $(( $RANDOM % 21600 )) \
        && echo "$(date): Starting caldav sync" \
        && export VDIRSYNCER_CONFIG=/config/vdirsyncer \
        && yes | /usr/bin/vdirsyncer discover \
        && /usr/bin/vdirsyncer sync
0 0,12 * * * \
    sleep $(( $RANDOM % 21600 )) \
        && echo "$(date): Starting mbsync " \
        && /usr/bin/mbsync -c /config/mbsyncrc fastmail' \
    | crontab -

mkdir -p "/data/mail"
mkdir -p "/data/calendars"
mkdir -p "/data/contacts"

# run CMD
echo "INFO: entrypoint complete; executing '${*}'"
exec "${@}"
