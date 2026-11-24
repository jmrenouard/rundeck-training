# Déployer Rundeck sous Docker Compose et Swarm

Cette procédure valide les manifestes Docker, démarre l'environnement Compose puis déploie la stack Swarm.

## Prérequis

- Docker Engine et Docker Compose V2 fonctionnent sur l'hôte.
- GNU Make existe sur l'hôte.
- Les ports `4440` et `3306` sont libres sur localhost.

## Procédure

1. Copiez le modèle d'environnement vers `docker/.env` si le fichier manque.

```bash
cp -n docker/.env.example docker/.env
```

2. Modifiez les mots de passe `MYSQL_PASSWORD` et `MYSQL_ROOT_PASSWORD` dans `docker/.env`.

3. Validez la syntaxe Compose avec le fichier d'environnement.

```bash
docker compose --env-file docker/.env -f docker/docker-compose.yml config -q
```

4. Démarrez les conteneurs `rundeck` et `mysql-db` en arrière-plan.

```bash
make -C docker up
```

5. Pour un cluster Swarm, déployez le manifeste `docker/docker-swarm.yml`.

```bash
docker stack deploy -c docker/docker-swarm.yml rundeck-stack
```

NOTE : Le mode Swarm utilise les volumes nommés `rundeck-data` et `mysql-data` sur un nœud manager.

## Vérification

1. Listez les conteneurs Compose pour confirmer que les deux services tournent.

```bash
make -C docker ps
```

2. Interrogez le point d'accès HTTP de Rundeck sur le port `4440`.

```bash
curl -fsS -I http://localhost:4440
```

3. Pour un déploiement Swarm, affichez l'état des réplicas.

```bash
docker stack services rundeck-stack
```

## Retour arrière

ATTENTION : Exécutez `make -C docker clean` uniquement si vous voulez supprimer les volumes et répertoires de données.

Pour arrêter les conteneurs Compose sans supprimer les volumes, exécutez la commande d'arrêt :

```bash
make -C docker down
```

Pour retirer la stack Swarm, exécutez la commande de suppression :

```bash
docker stack rm rundeck-stack
```
