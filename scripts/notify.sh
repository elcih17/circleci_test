#!/bin/bash

echo 'notify start'
abs_path=`echo $(cd $(dirname $0) && pwd)`
. ${abs_path}/notify_to_slack.sh

CIRCLE_DOMAIN="circleci.com"
API_END_POINT="https://${CIRCLE_DOMAIN}/api/v1/project/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
CIRCLE_TOKEN_PARAM="circle-token=$CIRCLE_REBUILD_TOKEN"

curr_build_id=$CIRCLE_BUILD_NUM #今回のビルドID
echo curr_build_id $curr_build_id
BUILD_RESULT_URL="https://${CIRCLE_DOMAIN}/gh/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/${curr_build_id}"
echo build_result_url $BUILD_RESULT_URL
BUILD_RESULT_FILE=$CIRCLE_ARTIFACTS/circleResult.txt
echo build_result_file $BUILD_RESULT_FILE

# ビルド結果は使いまわすのでファイルに書き込む
curl -s $API_END_POINT/$curr_build_id?$CIRCLE_TOKEN_PARAM > $BUILD_RESULT_FILE

BUILD_USER_NAME=$(cat $BUILD_RESULT_FILE | jq -r '.user.login')
PREVIOUS_BUILD_STATUS=$(cat $BUILD_RESULT_FILE | jq -r '.previous.status')

test_fail_cnt=$(cat $BUILD_RESULT_FILE | jq '[.steps[].actions[] | select(contains({failed:true})) | .status] | length')
echo test_fail_cnt $test_fail_cnt

SLACK_USER_NAME="okdBot"
SLACK_CHANNEL="#okada_test"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

echo notify to slack: $SLACK_USER_NAME $SLACK_CHANNEL

NOTIFY_TARGETS=("develop" "master")
# 通知対象ブランチでのテストに失敗していたら通知する
for branch in "${NOTIFY_TARGETS[@]}";
do
  if [ "$CIRCLE_BRANCH" = "$branch" ]; then
    if [ "$test_fail_cnt" -gt 0 ]; then
      # commit履歴を日付昇順ソートして、末尾から2番目の人を取る(末尾の人はmergeした人) hal1008とplaid-incは除く
      last_committer=$(cat $BUILD_RESULT_FILE|jq '.all_commit_details | sort_by(.committer_date)' | grep author_name | grep -v -e hal1008 -e plaid-inc | awk -F'"' '{print $4}' | tail -n2 | head -n1)
      echo last_committer:$last_committer
      message="<!here>\n $branchブランチでのテストが失敗しました。 :no_entry_sign: \n $last_committer さん、確認をお願いします。 :bow: \n $BUILD_RESULT_URL"
      notify_to_slack "$message" $SLACK_USER_NAME $SLACK_CHANNEL $SLACK_WEBHOOK_URL
      break
    fi
    if [ "$test_fail_cnt" -eq 0 ] && [ "$PREVIOUS_BUILD_STATUS" = "failed" ]; then
      # develop or masterブランチで前回のビルド結果がfailed、今回のビルド結果がfixedの場合に通知する
      message="<!here>\n 前回失敗していた$branchブランチのテストが成功しました。:white_check_mark:  \n $BUILD_RESULT_URL"
      notify_to_slack "$message" $SLACK_USER_NAME $SLACK_CHANNEL $SLACK_WEBHOOK_URL
      break
    fi
  fi
done

exit 0
