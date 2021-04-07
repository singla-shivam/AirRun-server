# AirRun

## Dev-env setup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server`

**Check the server health** - http://localhost:4002/_heatlh

## Local production deployment

#### Pre-requisites
System MUST have following installed and, up and running
* Docker
* Minikube
* Helm
* Kubectl

To deploy the app on Minikube, open a terminal and fire these commands

* This tells Minikube to use docker daemon already installed on your local machine
```
$ eval $(minikube docker-env)
```

* Install Helm postgres chart
```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm install p \
  --set postgresqlPassword=postgrespassword,postgresqlDatabase=air-run-prod \
    bitnami/postgresql
```

* Create database in the Postgres service
```bash
$ export POSTGRES_PASSWORD=$(kubectl get secret --namespace default p-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

$ kubectl run p-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.10.0-debian-10-r60 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host p-postgresql -U postgres -d postgres -p 5432
```
Press enter after connection and type
```psql
CREATE DATABASE "air-run-prod";
```

Exit from postgres shell by pressing Ctrl+D

* Create a secret in Minikube with following yaml
```yaml
kind: Secret
apiVersion: v1
metadata:
  name: air-run
  namespace: default
data:
  DATABASE_URL: ZWN0bzovL3Bvc3RncmVzOnBvc3RncmVzcGFzc3dvcmRAcC1wb3N0Z3Jlc3FsL2Fpci1ydW4tcHJvZA==
  GUARDIAN_SECRET_KEY: VGI4VzVXTExTb2x1V2o5Y2pwL1hzOUdGM1lncGNVYWNhTG1mNGcrMW84NG5GTXNQKy9lRjlFb2t3Ry8rQ1pEVwo=
  SECRET_KEY_BASE: VGI4VzVXTExTb2x1V2o5Y2pwL1hzOUdGM1lncGNVYWNhTG1mNGcrMW84NG5GTXNQKy9lRjlFb2t3Ry8rQ1pEVwo=
```

* Create another secret for calling air-run server-API from within the cluster. Replace the username and password.
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: air-run-service-account-basic-auth
type: kubernetes.io/basic-auth
stringData:
  username: admin
  password: t0p-Secret
```

* Build docker image in the context of Minikube
```bash
$ docker build -t air-run:latest .
```

* Deploy the app to Minikube using Helm Charts
```bash
$ helm install air-run-server air-run-deploy
```

In a few seconds, the app will be ready to be used
To call the API's run-
```bash
minikube ip
```

You will get the IP address of Minikube node
Then run
```bash
kubectl get service
# Example output -
# NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
# air-run                 NodePort    10.104.233.128   <none>        80:31887/TCP   22m
```

Note the port number of the service (31887 in this case)

You can call the API's by endpoint - http://\<minikube-ip\>:\<port\>/_health

### Create private docker registry
Ref - https://www.linuxtechi.com/setup-private-docker-registry-kubernetes/

After following above steps
* Create htpassword file
```bash
htpasswd -Bbn <user-name> <password>
```
Copy the output generated and save it in `pass-file` of the node in `/opt/certs/pass-file` directory.

Now deploy the private registry-
```bash
kubectl apply -f priv/private-registry.yaml
```

Now login with docker
```bash
docker login k8s-registry:31320
```

On your local machine, create a secret to be used by Kaniko while pushing to the repo
```bash
kubectl create secret generic kaniko-secret --from-file=~/.docker/config.json
```

Create another secret to be used as image pull secrete
```bash
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=~/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

### TODO
Add kaniko cache doc /opt/kaniko-cache

## Production Kubernetes cluster

### Prerequisites

### Install postgres

* Mount a persistent storage to /data of the node
* Create following directories in the /data
  1. /data/postgres
  2. /data/kaniko
  3. /data/uploads
* Add the following labels to the node with the persistent storage attached in last step
```bash
kubectl label nodes <node-name> air-run-postgres=true
kubectl label nodes <node-name> air-run-kaniko=true
```
* Create a persistent volume using
```bash
kubectl apply -f priv/mix-deploy/postgres-pv.yaml
```
* Deploy postgres database
```bash
mix air_run.postgres.init
```

### Setup registry

* Generate self-signed certificates for private docker repository
```bash
cd /data/kaniko/certs
sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout \
registry.key -x509 -days 365 -out registry.crt
```

* Create htpassword file
```bash
cd /data/kaniko/certs
htpasswd -Bbc pass-file <user-name> <password>
```

* Generate docker config secret
```bash
kubectl create secret docker-registry regcred \
  --docker-username=<user-name> \
  --docker-password=<password> \
  --docker-server=k8s-registry:31320
```

* Add new host `127.0.0.1 k8s-registry` to the node

* Create the deployment
```bash
kubectl apply -f priv/mix-deploy/private-registry.yaml
```