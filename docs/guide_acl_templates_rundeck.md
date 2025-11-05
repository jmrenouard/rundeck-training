<generate Complet des ACL Rundeck et PagerDuty Runbook Automation

Les Access Control Lists (ACL) de Rundeck et PagerDuty Runbook Automation permettent de contrôler finement les permissions des utilisateurs et groupes. Ce guide détaille cinq cas d'usage courants avec des exemples précis pour chaque scénario, ainsi qu'une comparaison entre Rundeck OSS et les versions Enterprise.

## Comprendre les ACL Rundeck

Les ACL Rundeck fonctionnent selon deux contextes principaux : le **contexte application** (pour les actions au niveau système) et le **contexte project** (pour les actions au sein d'un projet). Chaque règle ACL doit définir ces deux contextes pour fonctionner correctement.[1][2]

### Structure de Base d'une ACL

Une politique ACL se compose de quatre éléments essentiels:[2][1]

- **description** : description textuelle de la politique
- **context** : définit la portée (application ou project)
- **for** : déclare les types de ressources et règles d'autorisation
- **by** : définit à qui s'applique la politique (username, group, ou urn)

Les règles permettent d'**autoriser** (`allow`) ou de **refuser** (`deny`) des actions. Le mécanisme de décision fonctionne ainsi : si une règle correspond et autorise l'action, elle est marquée et continue ; si une règle correspond et refuse l'action, le système retourne DENIED et s'arrête. Pour qu'une action soit autorisée, il faut qu'une règle la permette et qu'aucune règle ne la refuse.[1]

## Cas d'Usage 1 : Groupe d'Administrateurs Rundeck

Un groupe d'administrateurs nécessite un accès complet à tous les projets, à la création de projets, à la gestion des utilisateurs et au système. Cela requiert **deux politiques ACL** : une pour le contexte application et une pour le contexte project.[3][2][1]

### ACL Administrateur - Contexte Project```yaml
description: Accès administrateur niveau projet - tous les projets
context:
  project: '.*'  # Tous les projets via regex
for:
  resource:
    - equals:
        kind: job
      allow: [create]  # Créer des jobs
    - equals:
        kind: node
      allow: [read,create,update,refresh]  # Gérer les sources de nœuds
    - equals:
        kind: event
      allow: [read,create]  # Accès à l'historique
    - equals:
        kind: webhook
      allow: [admin]  # Gestion complète des webhooks
  adhoc:
    - allow: [read,run,runAs,kill,killAs]  # Exécuter/arrêter des commandes adhoc
  job:
    - allow: [create,read,update,delete,run,runAs,kill,killAs,toggle_schedule,toggle_execution]  # Gestion complète des jobs
  node:
    - allow: [read,run]  # Lire et exécuter sur les nœuds
by:
  group: admin_rundeck
```

### ACL Administrateur - Contexte Application

```yaml
description: Accès administrateur niveau application
context:
  application: 'rundeck'
for:
  resource:
    - equals:
        kind: project
      allow: [create]  # Créer des projets
    - equals:
        kind: system
      allow: [read,enable_executions,disable_executions,admin]  # Contrôle système
    - equals:
        kind: system_acl
      allow: [read,create,update,delete,admin]  # Gérer les ACL système
    - equals:
        kind: user
      allow: [admin]  # Administrer les profils utilisateurs
    - equals:
        kind: runner
      allow: [admin]  # Gérer les Runners (Enterprise)
  project:
    - match:
        name: '.*'
      allow: [read,import,export,configure,delete,promote,admin]  # Accès complet aux projets
  project_acl:
    - match:
        name: '.*'
      allow: [read,create,update,delete,admin]  # Gérer les ACL projet
  storage:
    - allow: [read,create,update,delete]  # Accès au stockage de clés
by:
  group: admin_rundeck
```

**Points clés** : L'action `admin` sur les ressources donne un accès complet. Pour un contrôle total, il faut obligatoirement définir les deux contextes.[2][3][1]

## Cas d'Usage 2 : Administrateur par Projet

Un administrateur de projet peut gérer entièrement un projet spécifique (créer/modifier/supprimer des jobs, gérer les nœuds, configurer le projet) mais ne peut pas créer de nouveaux projets ou accéder aux autres projets.[4][3][2]

### ACL Admin Projet - Contexte Project

```yaml
description: Administrateur du projet MyProject uniquement
context:
  project: MyProject  # Nom exact du projet
for:
  resource:
    - equals:
        kind: job
      allow: [create,delete]  # Créer et supprimer des jobs
    - equals:
        kind: node
      allow: [read,create,update,refresh]  # Gérer les nœuds
    - equals:
        kind: event
      allow: [read,create]  # Accès historique
    - equals:
        kind: webhook
      allow: [admin]  # Gérer les webhooks du projet
  adhoc:
    - allow: [read,run,kill]  # Commandes adhoc
  job:
    - allow: [create,read,update,delete,run,kill,toggle_schedule,toggle_execution]  # Gestion complète des jobs
  node:
    - allow: [read,run]
by:
  group: admin_myproject
```

### ACL Admin Projet - Contexte Application

```yaml
description: Accès application pour admin projet MyProject
context:
  application: 'rundeck'
for:
  resource:
    - equals:
        kind: system
      allow: [read]  # Lire les infos système uniquement
  project:
    - equals:
        name: MyProject
      allow: [read,configure,import,export,delete_execution]  # Gérer le projet mais pas le supprimer
  project_acl:
    - equals:
        name: MyProject
      allow: [read,create,update,delete,admin]  # Gérer les ACL du projet (délégation)
  storage:
    - match:
        path: 'keys/project/MyProject/.*'  # Accès aux clés du projet uniquement
      allow: [read,create,update,delete]
by:
  group: admin_myproject
```

**Différence Enterprise** : Dans PagerDuty Runbook Automation, les ACL granulaires pour le key storage par projet sont disponibles depuis la version 3.4.1, permettant une isolation complète des secrets par projet. En OSS, l'accès au storage est uniquement au niveau système.[5][6]

## Cas d'Usage 3 : Compte en Lecture sur Toutes les Ressources Rundeck

Un compte en lecture seule peut visualiser tous les projets, tous les jobs, toutes les exécutions et l'historique, mais ne peut rien modifier ni exécuter.[7][8][9][10]

### ACL Lecture Seule - Contexte Project

```yaml
description: Lecture seule sur tous les projets
context:
  project: '.*'  # Tous les projets
for:
  resource:
    - allow: [read]  # Lecture seule sur toutes les ressources
  adhoc:
    - allow: [read]  # Voir les commandes adhoc mais pas les exécuter
  job:
    - allow: [read,view_history]  # Lire les jobs et voir l'historique
  node:
    - allow: [read]  # Voir les nœuds mais pas exécuter dessus
by:
  group: readonly_all
```

### ACL Lecture Seule - Contexte Application

```yaml
description: Lecture seule niveau application
context:
  application: 'rundeck'
for:
  resource:
    - equals:
        kind: system
      allow: [read]  # Lire les infos système
  project:
    - match:
        name: '.*'
      allow: [read]  # Voir tous les projets dans la liste
  storage:
    - allow: [read]  # Voir le storage (mais pas les clés sensibles)
by:
  group: readonly_all
```

**Note importante** : L'action `read` sur les jobs permet de voir la définition complète du job, y compris le workflow. Si tu veux permettre de voir l'existence du job sans sa définition, utilise uniquement `view` au lieu de `read`.[3][2]

## Cas d'Usage 4 : Lecture et Lancement de Jobs par Projet

Ce profil permet de voir et exécuter les jobs d'un projet spécifique, ainsi que d'arrêter les exécutions, mais sans pouvoir modifier les jobs ou la configuration du projet.[11][12][13][4][3]

### ACL Read/Run - Contexte Project

```yaml
description: Lecture et exécution des jobs sur ProjectX
context:
  project: ProjectX  # Nom du projet spécifique
for:
  resource:
    - equals:
        kind: event
      allow: [read,create]  # Accès à l'historique d'exécution
    - equals:
        kind: node
      allow: [read]  # Voir les nœuds
  adhoc:
    - allow: [read,run,kill]  # Exécuter et arrêter des commandes adhoc
  job:
    - allow: [read,run,kill]  # Lire, exécuter et arrêter des jobs
  node:
    - allow: [read,run]  # Exécuter sur les nœuds
by:
  group: executors_projectx
```

### ACL Read/Run - Contexte Application

```yaml
description: Accès application pour executors ProjectX
context:
  application: 'rundeck'
for:
  resource:
    - equals:
        kind: system
      allow: [read]  # Lire les infos système
  project:
    - equals:
        name: ProjectX
      allow: [read]  # Voir le projet
  storage:
    - match:
        path: 'keys/project/ProjectX/.*'
      allow: [read]  # Lire les clés du projet (nécessaire pour exécuter certains jobs)
by:
  group: executors_projectx
```

**Variante pour un groupe de jobs spécifique** : Si tu veux limiter l'exécution à un dossier de jobs uniquement (par exemple `/prod/maintenance`), ajoute une règle `match` sur le groupe de jobs:[12][13][14]

```yaml
  job:
    - equals:
        group: 'prod/maintenance'  # Limiter à un dossier spécifique
      allow: [read,run,kill]
    - match:
        group: '.*'  # Tous les autres jobs
      allow: [read]  # Lecture seule
```

## Cas d'Usage 5 : Compte en Lecture par Projet

Ce profil permet uniquement de visualiser un projet spécifique, ses jobs et l'historique des exécutions, sans pouvoir exécuter quoi que ce soit.[8][9][7]

### ACL Lecture Projet - Contexte Project

```yaml
description: Lecture seule sur ProjectY
context:
  project: ProjectY
for:
  resource:
    - allow: [read]  # Lecture des ressources
  adhoc:
    - allow: [read]  # Voir les commandes adhoc (sans exécuter)
  job:
    - allow: [read,view_history]  # Voir les jobs et leur historique
  node:
    - allow: [read]  # Voir les nœuds
by:
  group: readonly_projecty
```

### ACL Lecture Projet - Contexte Application

```yaml
description: Accès application pour lecture ProjectY
context:
  application: 'rundeck'
for:
  resource:
    - equals:
        kind: system
      allow: [read]
  project:
    - equals:
        name: ProjectY
      allow: [read]  # Voir uniquement ProjectY
  storage:
    - match:
        path: 'keys/project/ProjectY/.*'
      allow: [read]  # Voir le storage du projet (pas d'accès aux valeurs sensibles)
by:
  group: readonly_projecty
```

**Masquer les autres projets** : Avec cette configuration, l'utilisateur ne verra que ProjectY dans la liste des projets car il n'a pas l'autorisation `read` au niveau application pour les autres projets.[4][2]

## Différences entre Rundeck OSS et PagerDuty Runbook



### Gestion des ACL : Principales Différences

**Rundeck OSS (Community Edition)**:[15][16][17][1][2]
- Édition ACL via GUI avec éditeur de texte simple et validation syntaxique
- Fichiers `.aclpolicy` stockés sur le filesystem (`/etc/rundeck` ou `$RDECK_BASE/etc`)
- Outil en ligne de commande `rd-acl` pour tester et valider les ACL
- Support complet des fonctionnalités ACL de base (contexts, regex, deny, notBy)
- Accès au key storage au niveau système uniquement
- Pas de wizard graphique pour créer les ACL
- Pas de fonctionnalité de test ACL intégrée dans l'interface

**PagerDuty Runbook Automation (Enterprise/SaaS)**:[16][17][6][18][15][5]
- **ACL Policy Editor avec wizard graphique** : interface guidée pour créer des règles sans écrire de YAML manuellement
- **ACL Storage Layer optimisé** (depuis v3.4.0) : stockage des ACL dans la base de données pour de meilleures performances avec de nombreuses ACL[6]
- **Test ACL via GUI** : possibilité de tester les permissions directement dans l'interface pour un utilisateur ou groupe donné[19]
- **ACL granulaires pour Key Storage par projet** (depuis v3.4.1) : isolation complète des secrets au niveau projet au lieu du niveau système[5]
- **Délégation de l'administration des ACL projet** : les administrateurs peuvent déléguer la gestion des ACL projet aux admins de projet[17][15][4]
- **Configuration via GUI** : les paramètres sont stockés en base de données et peuvent être partagés entre les membres d'un cluster[5]
- Version SaaS : gestion uniquement via GUI, pas d'accès filesystem aux fichiers `.aclpolicy`[20][16]

### Fonctionnalités Enterprise Additionnelles

Les versions Enterprise et SaaS incluent également:[21][15][16][20]
- **Clustering et High Availability** : plusieurs instances Rundeck avec auto-takeover en cas de panne
- **Runners** (Process Runner pour Self-Hosted, Runbook Runner pour SaaS) : exécution sécurisée d'automation dans des environnements isolés
- **Webhooks avancés** : intégration avec PagerDuty, GitHub, AWS SNS avec signatures V3
- **Load Balanced Workloads** : distribution de charge entre membres du cluster
- **Support professionnel** et SLA 99.9% (SaaS uniquement)

### Compatibilité des ACL

**Important** : La syntaxe YAML des fichiers ACL est **identique entre toutes les versions** (OSS, Enterprise Self-Hosted, et SaaS). Les exemples fournis dans ce guide fonctionnent sur toutes les versions. La différence réside dans l'interface de gestion et les fonctionnalités avancées, pas dans le format des ACL.[18][15][1][2]

Les versions modernes supportent toutes:[1]
- Regex dans `username` et `group`
- Clause `deny` (depuis v1.2)
- Clause `notBy` (depuis v3.1)
- Support `urn:` dans `by` et `notBy` (depuis v3.4)


## Bonnes Pratiques et Conseils

### Organisation des Fichiers ACL

**Sépare tes ACL par groupe ou par usage** : Au lieu d'un seul fichier monolithique, crée plusieurs fichiers `.aclpolicy` :[2][1]
- `admin.aclpolicy` : groupe admin
- `project-admins.aclpolicy` : administrateurs de projets
- `readonly-users.aclpolicy` : utilisateurs en lecture seule
- `project-dev-executors.aclpolicy` : exécuteurs du projet dev

Cela facilite la maintenance et évite les conflits.

### Utilisation de Regex et URN

Pour **correspondances exactes** (éviter l'évaluation regex), utilise le format URN:[1]
```yaml
by:
  urn: 'group:exact_group_name'  # Correspondance exacte
  # Au lieu de:
  group: 'exact_group_name'  # Évalué comme regex
```

Pour **plusieurs projets similaires**, utilise les regex intelligemment:[2][1]
```yaml
context:
  project: '(dev|test|qa)_.*'  # Tous les projets dev_, test_, qa_
```

### Hiérarchie Allow/Deny

**Le deny l'emporte toujours sur allow**. Si une règle autorise une action mais qu'une autre la refuse, l'action sera refusée. Utilise `deny` avec précaution et de préférence avec `notBy` pour exclure certains utilisateurs:[1]

```yaml
# Tout le monde peut exécuter SAUF les stagiaires
for:
  job:
    - allow: [run]
      deny: []
by:
  group: 'team_.*'

notBy:
  group: 'stagiaires'
```

### Débogage et Validation

**Avant de déployer en production**:[9][2]
1. Valide la syntaxe YAML avec `rd-acl validate <fichier.aclpolicy>`
2. Teste avec `rd-acl test` pour simuler les permissions
3. Consulte `/var/log/rundeck/rundeck.audit.log` pour voir les décisions d'autorisation GRANTED/REJECTED/DENIED
4. Active le mode debug temporairement pour comprendre les évaluations de règles

**Dans PagerDuty Runbook Enterprise**, utilise l'évaluateur ACL intégré dans le GUI pour tester les permissions d'un utilisateur ou groupe avant déploiement.[19]

### Délégation Progressive

Commence par des **permissions restrictives** et ajoute progressivement :[3][4]
1. Commence avec lecture seule sur un projet
2. Ajoute run sur jobs spécifiques
3. Ajoute kill pour gérer les exécutions
4. Enfin, ajoute update/create si nécessaire

Cette approche limite les risques et suit le principe du moindre privilège.

### Gestion du Key Storage

Pour les projets nécessitant des clés SSH ou secrets :[5][2]
- **OSS** : accès au storage au niveau système uniquement via `storage:`
- **Enterprise 3.4.1+** : utilise les ACL granulaires par projet via le path `keys/project/<ProjectName>/.*`

Exemple Enterprise :
```yaml
storage:
  - match:
      path: 'keys/project/MyProject/.*'
    allow: [read]  # Lecture seule des clés du projet
```

### Troubleshooting Commun

**Problème** : L'utilisateur voit "Unauthorized" alors que l'ACL semble correcte.[9][2]

**Solutions** :
1. Vérifie que l'utilisateur appartient bien au groupe (page profil utilisateur)
2. Vérifie qu'il y a **à la fois** un contexte application ET project défini
3. Consulte `rundeck.audit.log` pour voir la dernière décision (GRANTED/REJECTED/DENIED)
4. Vérifie qu'il n'y a pas de règle `deny` qui s'applique
5. Pour accéder à un projet, l'utilisateur doit avoir `read` sur le projet dans le contexte application[4][2]

**Problème** : L'utilisateur ne peut pas créer de jobs alors qu'il a `allow: [create]` sur `job:`.[22]

**Solution** : Il faut **deux autorisations** pour créer un job :[22][2]
- `allow: [create]` sur `resource: kind: job` (générique)
- `allow: [create]` sur `job:` (spécifique)

Les ACL Rundeck offrent une granularité exceptionnelle pour contrôler précisément qui peut faire quoi dans ton environnement d'automatisation. En maîtrisant les contextes application et project, ainsi que la différence entre ressources génériques et spécifiques, tu peux créer des politiques de sécurité robustes adaptées à ton organisation.
