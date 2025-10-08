# Environnement de Développement Docker pour Rundeck

Ce répertoire fournit une configuration **Docker** pour déployer rapidement un environnement **Rundeck minimaliste**, idéal pour le développement local, le test de jobs, ou l'apprentissage.

## Philosophie de cet Environnement

Contrairement aux déploiements Ansible ou via les scripts qui installent une stack complète (avec Keycloak, MinIO, etc.), cet environnement Docker se concentre sur le strict nécessaire : **Rundeck et sa base de données MySQL**.

L'objectif est de fournir un environnement :
-   **Rapide** : Démarre en quelques secondes avec une seule commande.
-   **Isolé** : Ne pollue pas votre machine locale avec des dépendances.
-   **Reproductible** : Garantit que tous les développeurs travaillent avec la même configuration de base.
-   **Simple** : Facile à comprendre, à modifier et à maintenir.

## Contenu du Répertoire

-   `docker-compose.yml`: Le fichier principal pour définir et lancer les services avec Docker Compose.
-   `docker-swarm.yml`: Une configuration alternative pour un déploiement sur un cluster Docker Swarm.
-   `.env.example`: Un fichier d'exemple pour les variables d'environnement.
-   `Makefile`: Un ensemble de raccourcis pour simplifier la gestion de l'environnement.
-   `data/`: Ce répertoire est créé au premier lancement et contient toutes les données persistantes de Rundeck et MySQL.

## Démarrage Rapide

Suivez ces étapes pour lancer l'environnement :

### 1. Prérequis

-   Docker
-   Docker Compose

### 2. Créer le Fichier d'Environnement

Copiez le fichier d'exemple `.env.example` pour créer votre propre configuration locale.

```bash
cp .env.example .env
```

Le fichier `.env` vous permet de personnaliser les ports, les mots de passe et les chemins de données sans modifier les fichiers `docker-compose`. **Ne modifiez les valeurs par défaut que si nécessaire.**

### 3. Démarrer les Conteneurs

Utilisez la commande `make` pour démarrer la stack en arrière-plan.

```bash
make up
```

Cette commande va :
1.  Lire le fichier `docker-compose.yml`.
2.  Télécharger les images Docker de Rundeck et MySQL.
3.  Créer et démarrer les conteneurs.
4.  Créer les répertoires `./data/rundeck` et `./data/mysql` pour stocker les données.

### 4. Accéder à Rundeck

-   Ouvrez votre navigateur et allez à l'adresse [http://localhost:4440](http://localhost:4440) (ou le port que vous avez défini dans `.RUNDECK_PORT`).
-   Connectez-vous avec les identifiants par défaut :
    -   **Utilisateur** : `admin`
    -   **Mot de passe** : `admin`

## Gestion de l'Environnement avec `make`

Le `Makefile` fournit des commandes simples pour gérer le cycle de vie de l'environnement.

-   `make up`: Démarre les conteneurs.
-   `make down`: Arrête et supprime les conteneurs (les données dans `./data` sont conservées).
-   `make logs`: Affiche les logs en temps réel de tous les services.
-   `make ps`: Liste les conteneurs en cours d'exécution.
-   `make restart`: Redémarre les services.
-   `make clean`: **Commande destructive.** Arrête les conteneurs ET supprime le répertoire `./data`, effaçant ainsi toutes les données de Rundeck et de la base de données.
-   `make help`: Affiche toutes les commandes disponibles.

## Persistance des Données

Les données sont persistées sur votre machine locale dans le répertoire `docker/data/`.
-   `data/rundeck/`: Contient les projets, jobs, logs, clés, etc. de Rundeck.
-   `data/mysql/`: Contient les fichiers de la base de données MySQL.

Cela signifie que même si vous détruisez les conteneurs avec `make down`, vos données seront conservées et réutilisées la prochaine fois que vous ferez `make up`. Pour repartir de zéro, utilisez `make clean`.