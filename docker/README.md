# Documentation de l'environnement Docker

Ce répertoire contient la configuration Docker pour déployer Rundeck et une base de données MySQL. Il est conçu pour être utilisé avec Docker Compose pour le développement local et Docker Swarm pour un environnement de production.

## Contenu

- [`docker-compose.yml`](#docker-compose)
- [`docker-swarm.yml`](#docker-swarm)
- [`Makefile`](#makefile)
- `jobs/` : Ce répertoire est destiné à contenir des définitions de jobs Rundeck qui peuvent être montées en volume dans le conteneur Rundeck.

---

### Docker Compose

Le fichier `docker-compose.yml` est utilisé pour lancer un environnement de développement local. Il définit deux services :
- `rundeck` : L'application Rundeck.
- `db` : La base de données MySQL.

**Caractéristiques :**
- Les données de Rundeck et de MySQL sont persistées dans des répertoires locaux (`./data/rundeck` et `./data/mysql`) pour un accès facile.
- La configuration (ports, identifiants) est gérée via un fichier `.env`.

**Utilisation :**
1. Créez un fichier `.env` à la racine du répertoire `docker` en vous basant sur `.env.example`.
2. Exécutez `make up` pour démarrer les conteneurs.

---

### Docker Swarm

Le fichier `docker-swarm.yml` est conçu pour un déploiement sur un cluster Docker Swarm.

**Caractéristiques :**
- Utilise des volumes nommés gérés par Swarm pour la persistance des données.
- Configuré pour un déploiement sur un nœud manager (peut être ajusté).

**Utilisation :**
1. Assurez-vous que votre environnement Swarm est initialisé.
2. Assurez-vous que les variables d'environnement nécessaires sont disponibles sur le nœud manager.
3. Déployez la stack avec `make swarm-deploy`.

---

### Makefile

Le `Makefile` simplifie la gestion de l'environnement Docker avec des commandes courtes et faciles à retenir.

**Commandes principales :**

*   **Pour Docker Compose :**
    *   `make up` : Démarre les conteneurs en arrière-plan.
    *   `make down` : Arrête et supprime les conteneurs.
    *   `make logs` : Affiche les logs des conteneurs.
    *   `make ps` : Liste les conteneurs en cours d'exécution.
    *   `make restart` : Redémarre les services.

*   **Pour Docker Swarm :**
    *   `make swarm-deploy` : Déploie la stack sur le cluster Swarm.
    *   `make swarm-rm` : Supprime la stack du cluster.
    *   `make swarm-services` : Liste les services de la stack.

*   **Nettoyage :**
    *   `make clean` : Arrête les conteneurs et supprime tous les volumes de données (local et Docker). **Attention, cette commande est destructive.**

*   **Aide :**
    *   `make help` : Affiche la liste de toutes les commandes disponibles.