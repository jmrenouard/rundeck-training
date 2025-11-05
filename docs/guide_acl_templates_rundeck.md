# Guide Complet des ACL Rundeck et PagerDuty Runbook Automation

Les Access Control Lists (ACL) de Rundeck et PagerDuty Runbook Automation permettent de contrôler finement les permissions des utilisateurs et groupes. Ce guide détaille cinq cas d'usage courants avec des exemples précis pour chaque scénario, ainsi qu'une comparaison entre Rundeck OSS et les versions Enterprise.

## Comprendre les ACL Rundeck

Les ACL Rundeck fonctionnent selon deux contextes principaux : le **contexte application** (pour les actions au niveau système) et le **contexte project** (pour les actions au sein d'un projet). Chaque règle ACL doit définir ces deux contextes pour fonctionner correctement.

### Structure de Base d'une ACL

Une politique ACL se compose de quatre éléments essentiels:

- **description** : description textuelle de la politique
- **context** : définit la portée (application ou project)
- **for** : déclare les types de ressources et règles d'autorisation
- **by** : définit à qui s'applique la politique (username, group, ou urn)

Les règles permettent d'autoriser (`allow`) ou de refuser (`deny`) des actions. Le mécanisme de décision fonctionne ainsi : si une règle correspond et autorise l'action, elle est marquée et continue ; si une règle correspond et refuse l'action, le système retourne DENIED et s'arrête. Pour qu'une action soit autorisée, il faut qu'une règle la permette et qu'aucune règle ne la refuse.

## Cas d'Usage 1 : Groupe d'Administrateurs Rundeck

Un groupe d'administrateurs nécessite un accès complet à tous les projets, à la création de projets, à la gestion des utilisateurs et au système. Cela requiert deux politiques ACL : une pour le contexte application et une pour le contexte project.

### ACL Administrateur - Contexte Project

```yaml
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

**Points clés** : L'action `admin` sur les ressources donne un accès complet. Pour un contrôle total, il faut obligatoirement définir les deux contextes.

