# =====================================
# required environment variables
# * DEPLOYMENT_NAME
# * SERVICE_ACCOUNT_USERNAME
# * SERVICE_ACCOUNT_PASSWORD
# =====================================

apk add curl jq
sleep 10

while true
do
  sleep 5

  # get deployment object with name in $DEPLOYMENT_NAME
  deployment=$(
    curl \
    --header "Accept: application/json" \
    --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    --request GET \
    --cert-type DER \
    --cacert "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" \
    "https://kubernetes.default.svc/apis/apps/v1/namespaces/default/deployments/$DEPLOYMENT_NAME/status"
  )

  # required number of replicas
  replicas_required=$(
    echo "$deployment" \
    | jq '.status.replicas' -r
  )

  # available number of replicas
  replicas_available=$(
    echo "$deployment_status" \
    | jq '.status.availableReplicas' -r
  )

  echo "replicas_required: $replicas_required"
  echo "replicas_available: $replicas_available"

  # if the replica requirement is not met, continue polling
  if [[ $replicas_required != $replicas_available ]]
  then
    continue
  fi

  # the replica requirement is met
  data=$(echo "$deployment" | jq '{status: .status, "deployment-name": env.DEPLOYMENT_NAME}')

  curl \
  --header "Content-Type:application/json" \
  --request POST \
  --user "$SERVICE_ACCOUNT_USERNAME:$SERVICE_ACCOUNT_PASSWORD" \
  --data "$(echo "$data" | jq "tostring")" \
  http://air-run/callback/deployments/deployed

  break
done

echo "Done"