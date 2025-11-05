# Rundeck HA (Haute Disponibilité)

Bonjour \! C'est une excellente question, fondamentale dès que l'on souhaite assurer la robustesse et la scalabilité (montée en charge) de son service d'automatisation. La Haute Disponibilité (HA) pour Rundeck vise à garantir que le service (l'interface web, l'API, et surtout l'exécution des jobs) reste opérationnel même en cas de défaillance d'un des serveurs.

Je vais vous décrire les modèles de déploiement HA en m'appuyant sur la documentation que vous m'avez fournie, notamment le guide de déploiement en cluster (`pa-deployment-guide.pdf`).

-----

## Les Piliers de la Haute Disponibilité (HA)

Avant de détailler les modèles, il faut comprendre que *toute* configuration HA de Rundeck (ou PagerDuty Process Automation ) repose sur des composants partagés. Un nœud Rundeck seul est un "Single Point of Failure" (SPOF). Pour éviter cela, les membres du cluster *doivent* partager :

1.  **Une Base de Données Externe :** C'est le composant le plus critique. Tous les membres du cluster doivent pointer vers la *même* base de données (ex: MySQL, Postgres). C'est elle qui centralise l'état des jobs, les logs, l'historique, et qui coordonne les membres du cluster.
2.  **Un Stockage de Logs Partagé :** Pour que tous les membres du cluster puissent lire les logs de n'importe quelle exécution (peu importe quel membre l'a exécutée), les logs doivent être sur un stockage partagé (ex: S3, Azure Blob, ou un NFS).
3.  **Un Équilibreur de Charge (Load Balancer) :** Un composant réseau (ex: HAProxy, Nginx, AWS ELB) est placé devant les serveurs Rundeck pour distribuer le trafic des utilisateurs (UI et API) vers les nœuds actifs et sains.
4.  **Une Authentification Commune :** Tous les membres doivent utiliser la même source d'authentification (ex: LDAP, Active Directory, SSO) pour que les utilisateurs et les droits soient cohérents.

-----

## Modèle 1 : Le Cluster "Actif-Actif" (Modèle de base)

C'est le modèle le plus courant, appelé "Basic Cluster" dans la documentation.

### Théorie

Dans ce modèle, vous avez plusieurs nœuds Rundeck (au moins deux ) derrière un équilibreur de charge.

  * **Pour l'Interface (UI/API) :** Le cluster est "Actif-Actif". L'équilibreur de charge distribue les requêtes des utilisateurs entre *tous* les nœuds sains. Si un nœud tombe, l'équilibreur de charge arrête de lui envoyer du trafic, et les autres prennent le relais.
  * **Pour le Planificateur (Scheduler) :** Le cluster est "Actif-Passif". Un seul nœud à la fois est responsable du déclenchement des jobs planifiés. Les nœuds communiquent via la base de données (un système de "heartbeat" ou pulsation). Si le nœud "scheduler" actif tombe, un autre nœud prend automatiquement le relais (c'est la fonction "Autotakeover" ).

Ce modèle assure à la fois la haute disponibilité et la répartition de la charge des utilisateurs.

### Exemple de configuration (ébauche)

Voici à quoi ressemblerait la configuration clé dans `rundeck-config.properties` sur *chaque* membre du cluster :

```properties
# Activer le mode cluster
rundeck.cluster.mode.enabled=true 

# UUID unique pour CE nœud (CHAQUE nœud doit avoir un UUID différent)
rundeck.server.uuid = aaaaaaaa-bbbb-cccc-dddd-111111111111 

# URL publique du load balancer (que les utilisateurs voient)
grails.serverURL = http://rundeck.mon-entreprise.com

# Configuration de la base de données partagée (Ex: PostgreSQL)
dataSource.driverClassName = org.postgresql.Driver
dataSource.url = jdbc:postgresql://ma-db-partagee.example.com:5432/rundeck 
dataSource.username = rundeck
dataSource.password = "motdepasse"

# Configuration du stockage des logs partagé (Ex: S3)
rundeck.execution.logs.fileStorage.plugin=aws-s3-logstorage
rundeck.execution.logs.fileStorage.aws-s3-logstorage.bucket=mon-bucket-logs-rundeck 
```

-----

## Modèle 2 : Le Cluster "Actif-Passif" (Hot-Standby)

Ce modèle est aussi décrit dans le guide (`Active and Passive Cluster`).

### Théorie

Dans ce scénario, vous avez également plusieurs nœuds, mais un seul est "Actif" et gère *tout* (UI, API, et Scheduler). L'autre (ou les autres) est en "Passif" (hot-standby), prêt à prendre le relais.

L'équilibreur de charge est configuré pour n'envoyer *tout* le trafic que vers le nœud Actif.

Le basculement peut être :

1.  **Manuel :** Un administrateur doit reconfigurer l'équilibreur de charge pour pointer vers le nœud passif en cas de panne.
2.  **Automatique :** On utilise la fonction "Autotakeover". Le nœud passif surveille le nœud actif (via le heartbeat dans la BDD ). S'il détecte une défaillance, il se promeut "Actif" et l'équilibreur de charge (s'il est configuré pour un health check) redirige le trafic.

Ce modèle est plus simple pour la reprise après sinistre (Disaster Recovery) que pour la répartition de charge.

### Exemple de configuration (ébauche)

La configuration de base est similaire au modèle Actif-Actif, mais on y ajoute la configuration spécifique de l'Autotakeover (prise de contrôle automatique) dans `rundeck-config.properties`:

```properties
# (En plus des configurations 'cluster.mode.enabled' et 'dataSource' vues ci-dessus)

# Activer l'Autotakeover
rundeck.clusterMode.autotakeover.enabled=true 

# Configuration des pulsations (heartbeat)
rundeck.clusterMode.heartbeat.interval=30 
rundeck.clusterMode.heartbeat.delay=10 
rundeck.clusterMode.heartbeat.considerInactive=150 
rundeck.clusterMode.heartbeat.considerDead=300 
```

-----

## Modèle 3 : Architectures Avancées (Spécialisation et Runners)

Pour les très grands déploiements, la documentation mentionne des architectures plus complexes :

1.  **Serveurs Spécialisés :** On peut dédier certains nœuds du cluster à des rôles spécifiques. Par exemple, des nœuds "Frontend" (pour l'UI/API) et des nœuds "Backend" (pour l'exécution des jobs).
2. **Enterprise Runners :** Ces runners permettent d'exécuter des jobs dans des réseaux distants ou isolés. Ils fonctionnent en mode "pull" (polling) du cluster principal, ce qui sécurise l'accès dans des réseaux cloisonnés.
3. **Multi-clusters :** Pour les très grandes entreprises ou les besoins multi-environnements (DEV/QA/PROD), avec gestion centralisée du code des jobs via SCM (Git).

### Définition

Ce modèle vise les contextes d'automatisation à grande échelle. Il combine des mécanismes permettant :
- la spécialisation de serveurs (UI/API vs exécution de jobs),
- l'utilisation de Runners d'Entreprise pour orchestrer des exécutions dans des réseaux isolés/restreints,
- une répartition flexible ou segmentée des charges métier avec haute résilience.

#### Concepts clés

- **Serveurs spécialisés** : distinction entre nœuds "Frontend" (UI/API) et "Backend/Workers" (exécution jobs), afin d'optimiser les performances sous forte charge.
- **Enterprise Runners** : micro-services déléguant l'exécution de jobs dans des réseaux distants ou segmentés, en mode "pull" (polling du cluster principal).
- **Multi-clusters** : pour très grandes entreprises ou besoins multi-environnements (DEV/QA/PROD), gestion centralisée du code des jobs via SCM (Git).

### Tableau de récapitulatif – Modèle 3 avancé

| Paramètre | Description/Utilisation | Valeur par défaut / Recommandée | Définition |
|-----------|------------------------|--------------------------------|------------|
| Serveur spécialisé (UI / Worker) | Spécialiser des instances selon leur rôle : UI/API ou exécution de Jobs | N/A (dépend du sizing) | Au moins 1 UI et 1 Worker dès forte charge |
| Enterprise Runner | Service à déployer dans des réseaux distants. Exécute les jobs tagués selon des "Runner Tags" | Désactivé par défaut | Isoler/externaliser des exécutions réseaux |
| Nombre recommandé d'instances | Adapter à la charge (ex : 3+ pour la tolérance, 10+ si haute volumétrie) | 3 mini, 6+ en prod/secteur critique | Par ex : 4 UI + 6 Workers sur gros cluster |
| Base de données partagée | Même fonctionnement que modèle 1/2 : tous les membres du cluster et runners référencent la même base externalisée | Obligatoire | PostgreSQL, MariaDB, MySQL, Oracle |
| Stockage partagé (logs) | Obligatoire pour lecture des executions entre membres du cluster | S3, Azure Blob, NFS | Object storage compatible, checkpoint logs |
| Load balancer | Toujours requis pour distribuer UI/API (side "frontend") | HAProxy, NGINX, AWS ELB | Répartition/haute disponibilité interface |
| Authentification centralisée | Idem autre modèle (LDAP/AD/SSO) | SSO (OpenID v2 supporté, pas SAML 2023) | Cohérence utilisateurs/droits |
| Tag de runner | Attribut clé pour associer des jobs à exécuter sur un Runner spécifique (ex : "runner-paris", "runner-aws") | À définir selon organisation | Facilite la gestion multi-sites/enviro |
| Mode poll sur Runners | Les Runners n'exposent pas d'API directe, mais "poll" la tour principale pour prendre du travail | Activé | Sécurise accès dans réseaux cloisonnés |

### Compléments didactiques et bonnes pratiques

- **Raisonner en spécialisation spatiale** : dédier les Workers (exécutions lourdes) pour éviter de saturer l'UI sous charge importante.
- **Tagging des jobs pour runners** : s'assurer que chaque Runner a un tag unique ou partagé pour permettre la répartition adaptée/flexible.
- **Résilience** : il est recommandé d'avoir au moins deux Runners par "network zone" pour assurer la continuité de service en cas de panne locale.
- **Automatisation SCM/CI** : avec des multi-clusters, privilégier la gestion du code des jobs via Git pour intégration continue, promotions, DRP.
- **Sécurité** : les Runners n'ont pas besoin d'accès entrant, ils "pollent" (sortant uniquement), ce qui simplifie la configuration réseau/pare-feu.

### Exemple de flux d'exécution

1. Un utilisateur crée un job avec un tag Runner (ex : "runner-site-B").
2. Le cluster central attribue ce job au Runner correspondant, via polling.
3. Le Runner exécute la tâche sur les nœuds de son réseau local, et renvoie le statut au cluster central.
4. Les logs d'exécution sont centralisés (S3 ou équivalent), accessibles de tout le cluster.

---

**Ce modèle s'adresse aux plateformes nécessitant souplesse, isolation réseau, répartition massive des charges ou multitenancy.**


Absolument. Voici l'enrichissement de votre plan de documentation pour la haute disponibilité (HA) de PagerDuty Process Automation (Rundeck Enterprise) et des composants qui l'entourent.

L'architecture HA complète de Rundeck repose sur trois piliers :

1.  **Cluster Applicatif (Enterprise)** : Les nœuds Rundeck eux-mêmes, qui partagent un état (via la BDD) et des exécutions (via un log store partagé). Cette fonctionnalité est propre à **PagerDuty Process Automation (Enterprise)**.
2.  **Base de Données (BDD) en HA** : Le "cerveau" du cluster.
3.  **Load Balancer (LB) en HA** : Le "point d'entrée" unique pour les utilisateurs et les API.

Ce document détaille les piliers 2 et 3, qui sont essentiels au bon fonctionnement du pilier 1.

-----

## Chapitre 1 : NGINX en Haute Disponibilité pour Rundeck

Un Load Balancer est indispensable pour répartir le trafic (UI et API) entre les différents membres du cluster Rundeck Enterprise. S'il n'y a qu'un seul Load Balancer (comme NGINX), il devient lui-même un *Single Point of Failure* (SPOF). Ce chapitre explore les solutions pour rendre ce point d'entrée résilient.

### ⚙️ Solution 1 (On-Premise) : NGINX + Keepalived (Actif-Passif)

Cette solution est la plus courante pour les déploiements *on-premise* (hors cloud managé).

  * **Principe** : Deux serveurs NGINX (ou plus) partagent une adresse IP virtuelle (VIP) grâce au protocole VRRP, géré par `Keepalived`. Un seul serveur (le `MASTER`) détient la VIP à un instant T. S'il tombe, le serveur `BACKUP` la récupère en quelques secondes.
  * **Failover** : Automatique et rapide (2-5 secondes selon la configuration).

#### 💻 Exemple de Configuration NGINX (`/etc/nginx/conf.d/rundeck.conf`)

Cette configuration est nécessaire sur *tous* les nœuds NGINX. Elle définit le pool de serveurs Rundeck (le cluster Enterprise) et gère la terminaison SSL ainsi que les WebSockets (requis pour l'UI de Rundeck).

```nginx
# Pool de serveurs du cluster Rundeck Enterprise
upstream rundeck_cluster {
    # Mode "least_conn" pour équilibrer la charge intelligemment
    least_conn;
    server 10.0.1.10:4440; # Nœud Rundeck 1
    server 10.0.1.11:4440; # Nœud Rundeck 2
    server 10.0.1.12:4440; # Nœud Rundeck 3
}

server {
    listen 443 ssl http2;
    server_name rundeck.votreentreprise.com;

    # --- Terminaison SSL ---
    ssl_certificate /etc/nginx/ssl/rundeck.votreentreprise.com.crt;
    ssl_certificate_key /etc/nginx/ssl/rundeck.votreentreprise.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;

    # --- Proxy vers le cluster Rundeck ---
    location / {
        proxy_pass http://rundeck_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # --- Support WebSocket (Crucial pour l'UI Rundeck 4.x+) ---
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # --- Health Check (Optionnel mais recommandé) ---
        # Rundeck expose /health pour les checks
        health_check uri=/health interval=10s fails=3 passes=2;
    }
}
```

#### 💻 Exemple de Configuration Keepalived (`/etc/keepalived/keepalived.conf`)

Cette configuration gère l'IP virtuelle flottante (VIP).

```conf
! Configuration pour le Nœud NGINX MASTER
! (Adapter "priority" et "state" pour le nœud BACKUP)

global_defs {
   router_id NGINX_HA_01
}

# Script pour vérifier que NGINX tourne
vrrp_script chk_nginx {
    script "/usr/bin/pgrep nginx"
    interval 2
    weight 20
}

vrrp_instance VI_RUNDECK {
    state MASTER            # Mettre BACKUP sur l'autre nœud
    interface eth0          # Interface réseau
    virtual_router_id 51    # Doit être identique sur les deux nœuds
    priority 150            # Mettre 100 sur le nœud BACKUP
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass VOTRE_PASS_SECRET
    }
    
    virtual_ipaddress {
        192.168.1.100/24    # L'adresse VIP que les utilisateurs ciblent
    }
    
    track_script {
        chk_nginx
    }
}
```

  * ✅ **Avantages** : Solution robuste, éprouvée, relativement simple à mettre en œuvre *on-premise*. Failover automatique.
  * ❌ **Inconvénients** : Actif-Passif (le nœud BACKUP est dormant). Le failover, bien que rapide, n'est pas instantané et provoque une micro-coupure.

-----

### ⚙️ Solution 2 : DNS Round-Robin (Non Recommandé pour la HA)

  * **Principe** : Créer plusieurs enregistrements DNS (type A) pour le même nom d'hôte (`rundeck.votreentreprise.com`), pointant vers les différents serveurs NGINX.
  * ❌ **Inconvénients** :
      * **Pas de Health Check** : Si un nœud NGINX tombe, le DNS continuera d'envoyer des utilisateurs vers lui jusqu'à ce que l'enregistrement soit manuellement retiré.
      * **Cache DNS** : Les clients (navigateurs, serveurs) gardent les IP en cache. Le failover n'est pas géré.
      * **Répartition** : La répartition de charge est aléatoire et non basée sur la charge réelle.
  * **Cas d'usage** : Uniquement pour une répartition de charge basique, *pas* pour de la haute disponibilité.

-----

### ⚙️ Solution 3 : Load Balancer Cloud ou Matériel

  * **Principe** : Utiliser un service managé (AWS ALB/ELB, Azure Load Balancer, GCP Load Balancing) ou un équipement matériel dédié (F5, NetScaler) ou un logiciel dédié (HAProxy en cluster).
  * **Recommandation** : **C'est la solution recommandée en environnement Cloud.** Elle est nativement HA, gère le SSL, les health checks et le failover de manière transparente.
  * ✅ **Avantages** : Résilience gérée par le fournisseur, configuration simplifiée, haute performance, intégration facile des certificats SSL.
  * ❌ **Inconvénients** : Coût (matériel ou service cloud), "vendor lock-in" potentiel.

-----

### ⚠️ Risques de Sécurité (NGINX)

  * **Terminaison SSL** : Le NGINX doit utiliser des protocoles et ciphers forts (TLSv1.2, TLSv1.3) pour protéger les communications (voir exemple de config).
  * **Gestion des Secrets** : La clé privée SSL (`.key`) doit avoir des permissions très restrictives (`chmod 400`).
  * **Surface d'Attaque** : Le NGINX est exposé sur Internet. Il doit être maintenu à jour (fail2ban, WAF) pour prévenir les attaques (DDoS, injections).

-----

### 📚 Sources (Chapitre 1)

  * **NGINX (Auteur)** (2024). *NGINX Reverse Proxy*. [https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
  * **NGINX (Auteur)** (2024). *NGINX WebSocket support*. [https://nginx.org/en/docs/http/websocket.html](https://nginx.org/en/docs/http/websocket.html)
  * **Keepalived.org (Auteur)** (2024). *Keepalived Documentation*. [https://keepalived.org/doc/](https://keepalived.org/doc/)
  * **PagerDuty (Auteur)** (2024). *Load Balancer Configuration (Rundeck Docs)*. [https://docs.rundeck.com/docs/administration/cluster/load-balancer/](https://www.google.com/search?q=https://docs.rundeck.com/docs/administration/cluster/load-balancer/)

-----

## Chapitre 2 : MySQL/MariaDB en Haute Disponibilité

La base de données est le composant le plus critique. Elle stocke l'état des jobs, l'historique, les ACLs et la configuration du cluster (Enterprise). Si la base de données est inaccessible, **l'ensemble du cluster Rundeck est inutilisable**.

### ⚙️ Solutions Détaillées

#### 1\. Master-Slave (Réplication Asynchrone)

  * **Principe** : Un maître (`MASTER`) gère toutes les écritures. Les données sont répliquées (généralement de manière asynchrone) vers un esclave (`SLAVE`) en lecture seule.
  * **HA** : **Aucune.** Le failover est manuel (promouvoir le SLAVE en MASTER, reconfigurer Rundeck) et entraîne quasi-certainement une **perte de données** (les transactions non encore répliquées).
  * **Recommandation** : À n'utiliser que pour les backups déportés, *jamais* pour de la HA.

#### 2\. Master-Master + Keepalived

  * **Principe** : Similaire à NGINX+Keepalived. Deux serveurs MySQL sont en réplication Master-Master. Une VIP (gérée par Keepalived) pointe vers le serveur considéré comme "actif".
  * **HA** : Bonne solution *on-premise* de milieu de gamme. Le failover est automatique.
  * ❌ **Inconvénients** : Risque de conflits de réplication (surtout sur les clés auto-incrémentées) si l'on écrit sur les deux nœuds. La réplication reste asynchrone (faible risque de perte de données au moment du failover).

#### 3\. Galera Cluster / MySQL Group Replication (Multi-Master Synchrone)

  * **Principe** : C'est la solution *on-premise* la plus robuste. Tous les nœuds (3 au minimum, pour éviter le split-brain) sont des maîtres. Une écriture sur un nœud est répliquée de manière **synchrone** sur les autres *avant* que la transaction ne soit validée (COMMIT).
  * **HA** : Véritable multi-master. Zéro perte de données théorique en cas de panne d'un nœud.
  * **Recommandation** : **Pour les déploiements *on-premise* critiques (Enterprise).**

#### 4\. Services Cloud Gérés (RDS, Azure SQL, etc.)

  * **Principe** : Le fournisseur cloud (AWS, Azure, GCP) gère la complexité de la HA.
  * **Exemple (AWS RDS Multi-AZ)** : Une instance primaire et une instance "standby" dans une autre zone de disponibilité (AZ). La réplication est **synchrone**. En cas de panne, AWS bascule automatiquement le CNAME DNS vers l'instance standby.
  * **Recommandation** : **La solution recommandée pour tout déploiement Cloud.** Le coût est supérieur à une VM auto-gérée, mais la fiabilité et la simplicité d'administration sont incomparables.

-----

### 📊 Tableau Comparatif des Solutions DB

| Solution | Type HA | Failover | Perte Données | Complexité Admin | Cas d'usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Master-Slave | Aucune | Manuel | Élevé | Faible | Non-prod, Backups |
| Master-Master + Keepalived | Actif-Passif (via VIP) | Auto (secondes) | Faible (synchro) | Moyenne | PME On-Premise |
| **Galera Cluster** | **Actif-Actif (Multi-Master)** | N/A (synchrone) | **Zéro (théorique)** | **Élevé** | **Enterprise On-Premise** |
| **Cloud RDS (Multi-AZ)** | Actif-Passif (Managé) | **Auto (\< 1 min)** | **Zéro (synchrone)** | Très Faible | **Cloud (Recommandé)** |

-----

### 💻 Configuration Rundeck et ProxySQL

Pour que Rundeck bénéficie d'un cluster Galera, il ne doit pas cibler un seul nœud (qui pourrait tomber). Il doit cibler un point d'entrée stable.

  * **Option 1 (Simple)** : Utiliser une VIP (Keepalived) qui pointe vers les nœuds Galera (comme pour NGINX).
  * **Option 2 (Recommandée)** : Utiliser un proxy SQL comme **ProxySQL**.

`ProxySQL` est un proxy léger, conscient du protocole MySQL, qui se place entre Rundeck et le cluster Galera. Il gère les health checks, le load balancing des requêtes (lecture/écriture) et le failover de manière totalement transparente pour Rundeck.

#### 1\. Configuration Rundeck (`rundeck-config.properties`)

Rundeck doit pointer vers le *listener* de ProxySQL (ou la VIP).

```properties
# rundeck-config.properties

# L'URL pointe vers ProxySQL (ou la VIP)
dataSource.url = jdbc:mysql://127.0.0.1:6033/rundeck?autoReconnect=true&useSSL=false

# Note : Si vous utilisez RDS ou un service cloud,
# mettez l'endpoint fourni par le provider ici.
# ex: jdbc:mysql://rundeck-prod.xxxxx.eu-west-1.rds.amazonaws.com:3306/rundeck

dataSource.username = rundeck_user
dataSource.password = (mot de passe sécurisé)
dataSource.driverClassName = com.mysql.cj.jdbc.Driver
```

#### 2\. Exemple de Configuration ProxySQL (`/etc/proxysql.cnf`)

ProxySQL se configure via son interface d'administration (port 6032) ou via `proxysql.cnf`.

```ini
# Définition des "Hostgroups" Galera
# ProxySQL va répartir les écritures sur le HG 10, les lectures sur le HG 20
mysql_replication_hostgroups = (
    {
        writer_hostgroup = 10
        reader_hostgroup = 20
        comment = "Galera Cluster"
    }
)

# Définition des serveurs Galera réels
mysql_servers = (
    {
        address = "10.0.1.20"
        port = 3306
        hostgroup = 10         # Appartient au HG écriture
        max_connections = 200
    },
    {
        address = "10.0.1.21"
        port = 3306
        hostgroup = 10
        max_connections = 200
    },
    {
        address = "10.0.1.22"
        port = 3306
        hostgroup = 10
        max_connections = 200
    }
)

# Définition des utilisateurs (Rundeck s'y connecte)
mysql_users:
{
    username = "rundeck_user"
    password = "PASSWORD_UTILISE_PAR_RUNDECK"
    default_hostgroup = 10 # Envoie les requêtes vers le HG 10 par défaut
}
```

#### 3\. Exemple de Configuration Galera (`/etc/mysql/conf.d/galera.cnf`)

Cette configuration est nécessaire sur *chaque* nœud MySQL/MariaDB du cluster.

```ini
[mysqld]
# --- Configuration de base Galera ---
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# --- Adresses des membres du cluster ---
wsrep_cluster_address="gcomm://10.0.1.20,10.0.1.21,10.0.1.22"

# --- Nom du cluster (doit être identique) ---
wsrep_cluster_name="rundeck_galera_prod"

# --- Identification de ce nœud ---
wsrep_node_address="10.0.1.20"  # (Changer sur chaque nœud)
wsrep_node_name="mysql-node-1"  # (Changer sur chaque nœud)

# --- Configuration InnoDB (obligatoire) ---
binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
```

-----

### ⚠️ Risques de Sécurité et Recommandations (Base de données)

1.  **Backups** : La HA n'est *pas* un backup. Des `mysqldump` réguliers ou des snapshots (si Cloud) restent obligatoires pour se prémunir contre une erreur humaine (ex: `DELETE` sans `WHERE`).
2.  **Accès Réseau** : Le port de la base de données (3306) ne doit **jamais** être exposé publiquement. Il ne doit être accessible *que* depuis les nœuds du cluster Rundeck et les nœuds d'administration (via des règles de firewall / security groups stricts).
3.  **Permissions** : L'utilisateur `rundeck_user` ne doit avoir que les permissions `GRANT ALL PRIVILEGES` *uniquement* sur la base `rundeck` (`GRANT ALL ON rundeck.* TO 'rundeck_user'@'...'`).
4.  **Chiffrement des Secrets** : Dans `rundeck-config.properties`, le `dataSource.password` est en clair (OSS). Pour PagerDuty Process Automation (Enterprise), il est *fortement* recommandé d'utiliser le [Storage Encryption](https://www.google.com/search?q=https://docs.rundeck.com/docs/administration/security/storage-encryption.html) pour chiffrer cette valeur (par ex. via HashiCorp Vault ou JCEKS).

-----

### 📚 Sources (Chapitre 2)

  * **MariaDB (Auteur)** (2024). *MariaDB Galera Cluster*. [https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/)
  * **ProxySQL (Auteur)** (2024). *ProxySQL Documentation*. [https://proxysql.com/documentation/](https://proxysql.com/documentation/)
  * **Amazon Web Services (Auteur)** (2024). *Haute disponibilité (Multi-AZ) pour Amazon RDS*. [https://docs.aws.amazon.com/fr\_fr/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html](https://docs.aws.amazon.com/fr_fr/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
  * **PagerDuty (Auteur)** (2024). *Database - Rundeck Administration*. [https://docs.rundeck.com/docs/administration/configuration/database/](https://docs.rundeck.com/docs/administration/configuration/database/)

-----

## Conclusion

La mise en place d'une architecture Rundeck/PagerDuty Process Automation totalement résiliente est un processus en trois étapes qui élimine tous les points de défaillance uniques :

1.  **HA du Load Balancer (Ex: NGINX + Keepalived ou ALB Cloud)** : Garantit un point d'entrée toujours disponible.
2.  **HA de la Base de Données (Ex: Galera Cluster ou RDS Multi-AZ)** : Garantit l'intégrité et la disponibilité de l'état du système.
3.  **Cluster Applicatif Rundeck Enterprise** : Permet à l'application elle-même de survivre à la perte d'un ou plusieurs nœuds.

La combinaison de ces trois éléments est la référence (le "gold standard") pour un déploiement de production critique de PagerDuty Process Automation.
