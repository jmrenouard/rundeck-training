# Référentiel des droits ACL Rundeck

Ce tableau liste l'ensemble des droits ACL (Access Control List) utilisables dans les fichiers de sécurité Rundeck.  
Chaque ligne détaille la ressource concernée, son contexte, le nom de l'action et une définition explicite.

| Ressource         | Contexte         | Action              | Description                                                                 |
|-------------------|------------------|---------------------|-----------------------------------------------------------------------------|
| job               | project          | read                | Voir un job, ses exécutions et lire sa définition                           |
| job               | project          | view                | Voir un job et ses exécutions (sans définition)                             |
| job               | project          | update              | Modifier un job                                                             |
| job               | project          | delete              | Supprimer un job                                                            |
| job               | project          | run                 | Exécuter un job                                                             |
| job               | project          | runAs               | Exécuter un job en tant qu'autre utilisateur                                |
| job               | project          | kill                | Arrêter une exécution de job                                                |
| job               | project          | killAs              | Arrêter une exécution en tant qu'autre utilisateur                          |
| job               | project          | create              | Créer le job correspondant                                                  |
| job               | project          | toggle_schedule     | Activer/désactiver le planning du job                                       |
| job               | project          | toggle_execution    | Activer/désactiver l'exécution du job                                       |
| job               | project          | scm_create          | Créer un job via plugin SCM uniquement                                      |
| job               | project          | scm_update          | Mettre à jour un job via plugin SCM                                         |
| node              | project          | read                | Voir le nœud dans l'UI                                                      |
| node              | project          | run                 | Exécuter des jobs/adhoc sur le nœud                                         |
| node              | project          | create              | Créer de nouvelles entrées de nœud                                          |
| node              | project          | update              | Modifier les entrées de nœud                                                |
| node              | project          | refresh             | Rafraîchir l'entrée de nœud depuis une URL                                  |
| adhoc             | project          | read                | Lire la sortie d'une exécution adhoc                                        |
| adhoc             | project          | run                 | Exécuter une commande adhoc                                                 |
| adhoc             | project          | runAs               | Exécuter une commande adhoc en tant qu'autre utilisateur                    |
| adhoc             | project          | kill                | Arrêter une exécution adhoc                                                 |
| adhoc             | project          | killAs              | Arrêter une exécution adhoc en tant qu'autre utilisateur                    |
| project (app)     | application      | read                | Voir un projet dans la liste des projets                                    |
| project (app)     | application      | configure           | Voir et modifier la configuration du projet                                 |
| project (app)     | application      | delete              | Supprimer le projet                                                         |
| project (app)     | application      | import              | Importer des archives dans le projet                                        |
| project (app)     | application      | export              | Exporter le projet en tant qu'archive                                       |
| project (app)     | application      | scm_import          | Utiliser le plugin SCM import                                               |
| project (app)     | application      | scm_export          | Utiliser le plugin SCM export                                               |
| project (app)     | application      | delete_execution    | Supprimer des exécutions                                                    |
| project (app)     | application      | admin               | Accès complet au projet                                                     |
| resource job      | project          | create              | Créer un nouveau job (générique)                                            |
| resource job      | project          | delete              | Supprimer des jobs (générique)                                              |
| resource job      | project          | scm_create          | Créer un job via SCM uniquement (générique)                                 |
| resource job      | project          | scm_delete          | Supprimer un job via SCM uniquement (générique)                             |
| resource node     | project          | read                | Lire les informations de nœud                                               |
| resource node     | project          | create              | Créer de nouvelles entrées de nœud                                          |
| resource node     | project          | update              | Modifier les entrées de nœud                                                |
| resource node     | project          | refresh             | Rafraîchir l'entrée de nœud                                                 |
| resource event    | project          | read                | Lire les événements d'historique                                            |
| resource event    | project          | create              | Créer des entrées d'événements arbitraires                                  |
| system            | application      | read                | Lire les informations système                                               |
| system            | application      | enable_executions   | Activer les exécutions                                                      |
| system            | application      | disable_executions  | Désactiver les exécutions                                                   |
| system            | application      | admin               | Contrôle complet du système                                                 |
| storage           | application      | read                | Lire les fichiers de stockage                                               |
| storage           | application      | create              | Créer des fichiers dans le storage                                          |
| storage           | application      | update              | Modifier les fichiers dans le storage                                       |
| storage           | application      | delete              | Supprimer des fichiers dans le storage                                      |
| system_acl        | application      | read                | Lire les fichiers ACL système                                               |
| system_acl        | application      | create              | Créer des fichiers ACL système                                              |
| system_acl        | application      | update              | Mettre à jour les fichiers ACL système                                      |
| system_acl        | application      | delete              | Supprimer les fichiers ACL système                                          |
| system_acl        | application      | admin               | Accès complet aux ACL système                                               |
| project_acl       | application      | read                | Lire les fichiers ACL projet                                                |
| project_acl       | application      | create              | Créer des fichiers ACL projet                                               |
| project_acl       | application      | update              | Mettre à jour les fichiers ACL projet                                       |
| project_acl       | application      | delete              | Supprimer les fichiers ACL projet                                           |
| project_acl       | application      | admin               | Accès complet aux ACL projet                                                |
| user              | application      | admin               | Modifier les profils utilisateur                                            |
| runner            | application/project | read             | Lire la config des Runners                                                  |
| runner            | application/project | create           | Créer de nouvelles entrées Runner                                           |
| runner            | application/project | update           | Mettre à jour les entrées Runner                                            |
| runner            | application/project | delete           | Supprimer des entrées Runner                                                |
| runner            | application/project | admin            | Accès complet aux Runners                                                   |

> **Astuce** : dans vos fichiers de règles ACL, référencer ces actions dans les blocs `by:`, `for:`, et `context:`, selon vos besoins de contrôle d'accès.
>
> Exemple de syntaxe :
```yaml
by:
  - group: admin
for:
  - resource: job
    context: project
    allowed: [read, run, create]
```

---

Ce tableau est à jour selon le fichier source `rundeck_acl_actions.csv`.  
Pour tout ajout futur, compléter ce tableau directement dans la documentation.
