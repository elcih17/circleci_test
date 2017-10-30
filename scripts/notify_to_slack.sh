#!/bin/bash
# 引き数を渡す際に、デフォルトだとスペース区切りでパラメタが渡されるので、改行区切りにしてスペース区切りの文字列を1つの引き数として扱う
IFS_BACKUP=${IFS}
IFS=$'\n'
notify_to_slack() {
  local MSG=${1:-"message"}
  local USER_NAME=${2:-"user name"}
  local CHANNEL=$3
  local WEBHOOK_URL=$4

  post_data=`cat <<-EOF
  payload={
    "channel": "$CHANNEL",
    "username": "$USER_NAME",
    "text": "$MSG"
  }
EOF`
  echo "$post_data"
  curl -X POST $WEBHOOK_URL --data-urlencode "$post_data"
}

IFS=${IFS_BACKUP}

