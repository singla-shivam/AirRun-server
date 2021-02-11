export K8S_APISERVER="https://kubernetes.default.svc"
export K8S_SERVICEACCOUNT="/var/run/secrets/kubernetes.io/serviceaccount"
export K8S_NAMESPACE=$(cat "${K8S_SERVICEACCOUNT}/namespace")
export K8S_TOKEN=$(cat "${K8S_SERVICEACCOUNT}/token")
export K8S_CACERT="${K8S_SERVICEACCOUNT}/ca.crt"
curl --cacert ${K8S_CACERT} --header "Authorization: Bearer ${K8S_TOKEN}" -X GET ${K8S_APISERVER}/api

./bin/air_run eval "AirRun.Release.migrate"
./bin/air_run start