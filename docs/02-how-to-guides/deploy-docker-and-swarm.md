# Deploy Rundeck with Docker Compose and Swarm

This procedure validates Docker manifests, starts the Compose lab, and deploys the Swarm stack file.

## Prerequisites

- Docker Engine and Docker Compose V2 exist on the host.
- GNU Make exists on the host.
- Ports `4440` and `3306` are free on localhost.

## Procedure

1. Copy the environment example file to `docker/.env` if `docker/.env` is absent.

```bash
cp -n docker/.env.example docker/.env
```

2. Edit `docker/.env` to set strong passwords for `MYSQL_PASSWORD` and `MYSQL_ROOT_PASSWORD`.

3. Validate the Compose manifest syntax with the environment file.

```bash
docker compose --env-file docker/.env -f docker/docker-compose.yml config -q
```

4. Start the `rundeck` and `mysql-db` containers in detached mode.

```bash
make -C docker up
```

5. For a Swarm cluster, initialize Swarm and deploy `docker/docker-swarm.yml`.

```bash
docker stack deploy -c docker/docker-swarm.yml rundeck-stack
```

NOTE: The Swarm manifest mounts named volumes (`rundeck-data` and `mysql-data`) on a manager node.

## Verification

1. List the Compose containers to confirm that both services run.

```bash
make -C docker ps
```

2. Query the Rundeck HTTP endpoint on port `4440`.

```bash
curl -fsS -I http://localhost:4440
```

3. For Swarm deployments, check the service replica counts.

```bash
docker stack services rundeck-stack
```

## Rollback

CAUTION: Run `make -C docker clean` only when you want to delete all local data directories and volumes.

To stop the Compose containers without volume deletion, run `make -C docker down`:

```bash
make -C docker down
```

To remove the Swarm stack, run `docker stack rm rundeck-stack`:

```bash
docker stack rm rundeck-stack
```
