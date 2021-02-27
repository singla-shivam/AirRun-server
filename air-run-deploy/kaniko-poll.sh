# =====================================
# required environment variables
# * JOB_NAME
# * $SERVICE_ACCOUNT_USERNAME
# * $SERVICE_ACCOUNT_PASSWORD
# =====================================

apk add curl jq
sleep 10

while true
do
  sleep 5

  # get pods realated the given job in $JOB_NAME
  pod_list=$(
    curl \
    --header "Accept: application/json" \
    --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    --request GET \
    --cert-type DER \
    --cacert "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" \
    "https://kubernetes.default.svc/api/v1/namespaces/default/pods/?labelSelector=job_name=$JOB_NAME"
  )

  # extract build container state from the pod list fetched
  container_state=$(
    echo "$pod_list" \
    | jq '.items' \
    | jq '.[0].status.containerStatuses' \
    | jq '.[] | select(.name == "kaniko-build")' \
    | jq '.state' \
  )

  echo "$container_state"

  # get the running property from the container state
  running_type=$(echo "$container_state" | jq '.running' | jq 'type' -r)
  # running property exists if its type is object (i.e. it is not null)
  # it means the build is currently running, so continue polling
  if [[ $running_type != "null" ]]
  then
    continue
  fi

  # the build container is terminated
  # either successfully built or terminated with an error
  # the air-run server will handle the cases
  data=$(echo "$container_state" | jq '{status: ., "job_name": env.JOB_NAME}')

  curl \
  --header "Content-Type:application/json" \
  --request POST \
  --user "$SERVICE_ACCOUNT_USERNAME:$SERVICE_ACCOUNT_PASSWORD" \
  --data "$(echo "$data" | jq "tostring")" \
  http://air-run/callback/deployments/built

  break
done

echo "Done"