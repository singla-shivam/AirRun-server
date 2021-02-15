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

Now deploy the private registry-
```bash
kubectl apply -f priv/private-registry.yaml
```
