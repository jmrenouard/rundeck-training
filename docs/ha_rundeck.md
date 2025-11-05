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


