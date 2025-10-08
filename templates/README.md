# Bibliothèque de Templates de Jobs Rundeck

Ce répertoire contient une collection de **templates de jobs Rundeck** prêts à l'emploi, conçus pour automatiser une large gamme de tâches d'administration système sur des plateformes **Linux** et **Windows**. Chaque template est fourni au format YAML et peut être importé directement dans votre projet Rundeck.

## Qu'est-ce qu'un Job Rundeck ?

Un job Rundeck est un workflow automatisé qui exécute une série d'étapes (commandes, scripts, etc.) sur des nœuds cibles. Les templates fournis ici sont des définitions de jobs pré-construites qui incluent :
- Des **options** pour paramétrer l'exécution (ex: nom d'un service, chemin d'un fichier).
- Des **étapes de workflow** logiques.
- Des **descriptions** et des **groupes** pour une meilleure organisation.

## Comment Importer un Template

1.  Naviguez vers votre projet dans l'interface Rundeck.
2.  Allez dans la section **Jobs**.
3.  Cliquez sur le bouton **"Upload Definition"** (ou "Charger une définition").
4.  Sélectionnez le fichier YAML du template que vous souhaitez utiliser.
5.  Rundeck importera le job, qui sera immédiatement disponible pour être exécuté.

**Note :** De nombreux jobs utilisent des options sécurisées pour les mots de passe ou les clés API. Celles-ci doivent être configurées dans le **Key Storage** de votre projet avant l'exécution.

---

## Organisation des Templates

Les templates sont organisés par plateforme et par catégorie fonctionnelle.

### Plateforme : Linux

#### Maintenance
- **`update_system.yaml`**: Met à jour les paquets (apt).
- **`cleanup_system.yaml`**: Nettoie les fichiers temporaires et les logs.
- **`restart_service.yaml`**: Redémarre un service `systemd`.
- **`check_service_status.yaml`**: Vérifie le statut d'un service.
- **`execute_remote_script.yaml`**: Télécharge et exécute un script depuis une URL.

#### Déploiement
- **`deploy_from_git.yaml`**: Clone ou met à jour un dépôt Git et exécute une commande de build.
- **`deploy_docker_container.yaml`**: Déploie une application conteneurisée avec Docker.
- **`deploy_jar_app.yaml`**: Déploie une application Java (JAR).

#### Sauvegarde & Restauration
- **`backup_files.yaml`**: Crée une archive `tar.gz` de répertoires spécifiés.
- **`restore_files.yaml`**: Restaure des fichiers depuis une archive `tar.gz`.
- **`backup_database_mysql.yaml`**: Sauvegarde une base de données MySQL avec `mysqldump`.
- **`restore_database_mysql.yaml`**: Restaure une base de données MySQL.

#### Sécurité
- **`create_user.yaml`**: Crée un nouvel utilisateur système.
- **`delete_user.yaml`**: Supprime un utilisateur et son répertoire personnel.
- **`add_user_to_group.yaml`**: Ajoute un utilisateur à un groupe.
- **`check_suid_guid.yaml`**: Recherche les fichiers avec des permissions potentiellement dangereuses (SUID/GUID).

---

### Plateforme : Windows

#### Maintenance
- **`update_system.yaml`**: Installe les mises à jour Windows en attente via PowerShell.
- **`cleanup_system.yaml`**: Nettoie les fichiers temporaires.
- **`restart_service.yaml`**: Redémarre un service Windows.
- **`check_service_status.yaml`**: Vérifie le statut d'un service.

#### Déploiement
- **`deploy_iis_app.yaml`**: Déploie une application web sur un serveur IIS.
- **`deploy_windows_service.yaml`**: Installe un nouveau service Windows.

#### Sauvegarde & Restauration
- **`backup_files.yaml`**: Crée une archive ZIP de répertoires.
- **`restore_files.yaml`**: Restaure des fichiers depuis une archive ZIP.
- **`backup_database_mssql.yaml`**: Sauvegarde une base de données Microsoft SQL Server.
- **`restore_database_mssql.yaml`**: Restaure une base de données Microsoft SQL Server.

#### Sécurité
- **`create_user.yaml`**: Crée un nouvel utilisateur local.
- **`delete_user.yaml`**: Supprime un utilisateur local.
- **`add_user_to_group.yaml`**: Ajoute un utilisateur à un groupe local.
- **`check_open_ports.yaml`**: Vérifie les ports TCP ouverts.

---

### Intégration & Services

#### MinIO / S3
- **`transfert-s3.yml`**: Transfère un fichier depuis un nœud local vers un bucket S3/MinIO. Idéal pour externaliser les sauvegardes.

#### Reporting
- **`report_disk_usage.yaml`**: Génère et envoie un rapport sur l'utilisation de l'espace disque.
- **`report_memory_usage.yaml`**: Génère et envoie un rapport sur l'utilisation de la mémoire.

---

### Templates de Base

Ces templates fournissent un point de départ pour créer vos propres jobs avec des exécuteurs spécifiques.

- **`ansible_job_template.yaml`**: Un job de base pour exécuter un playbook Ansible.
- **`bash_job_template.yaml`**: Un job simple pour exécuter un script Bash.
- **`python_job_template.yaml`**: Un job simple pour exécuter un script Python.