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