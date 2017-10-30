#!/bin/bash

abs_path=`echo $(cd $(dirname $0) && pwd)`
. ${abs_path}/notify_to_slack.sh

curr_build_id=$CIRCLE_BUILD_NUM #今回のビルドID
BUILD_RESULT_URL="https://${CIRCLE_DOMAIN}/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${curr_build_id}"

test_fail_cnt=$(cat $BUILD_RESULT_FILE | jq '[.steps[].actions[] | select(contains({failed:true})) | .status] | length')
echo test_fail_cnt $test_fail_cnt

SLACK_USER_NAME="okdBot"
SLACK_CHANNEL="#okada_test"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# develop or masterブランチでのテストに失敗していたら通知する
TARGETS=("develop" "master")

if [ "$test_fail_cnt" -gt 0 ]; then
  for branch in "${TARGETS[@]}"; do
    if [[ "$CIRCLE_BRANCH" = "$branch"]]; then
      last_committer="okd"
      echo last_committer:$last_committer
      message="<!here>\n $iブランチでのテストが失敗しました。 :no_entry_sign: \n $last_committer さん、確認をお願いします。 :bow: \n $BUILD_RESULT_URL"
      notify_to_slack "$message" $SLACK_USER_NAME $SLACK_CHANNEL $SLACK_WEBHOOK_URL
    fi
  break
  done
fi

# develop or masterブランチで前回のビルド結果がfailed、今回のビルド結果がfixedの場合に通知する
if [ "$test_fail_cnt" -eq 0]; then
  for branch in "${TARGETS[@]}"; do
    if [[ "$CIRCLE_BRANCH" = "$branch"]] && [ "$PREVIOUS_BUILD_STATUS" = "failed" ]; then
      message="<!here>\n 前回失敗していたdevelopブランチのテストが成功しました。 :white_check_mark: \n $BUILD_RESULT_URL"
      notify_to_slack "$message" $SLACK_USER_NAME $SLACK_CHANNEL $SLACK_WEBHOOK_URL
    fi
  break
  done
fi



