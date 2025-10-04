# Documentation des Templates Rundeck

Ce répertoire contient des templates de jobs pour Rundeck, prêts à l'emploi pour différentes plateformes et cas d'usage. Chaque template est fourni au format YAML et peut être importé directement dans votre projet Rundeck.

Les templates sont organisés par système d'exploitation (Linux, Windows) et par catégorie fonctionnelle.

## Templates Linux

Les templates pour Linux se trouvent dans le répertoire `templates/linux`.

### Déploiement (`linux/deployment`)

- **`deploy_jar_app.yaml`**: Déploie une application Java (JAR) sur un serveur Linux.
- **`deploy_war_app.yaml`**: Déploie une application web (WAR) sur un serveur d'applications comme Tomcat.
- **`deploy_docker_container.yaml`**: Déploie une application conteneurisée avec Docker.
- **`deploy_from_git.yaml`**: Clone ou met à jour un dépôt Git et exécute une commande de build.

### Maintenance (`linux/maintenance`)

- **`update_system.yaml`**: Met à jour les paquets d'un système Linux basé sur Debian/Ubuntu.
- **`cleanup_system.yaml`**: Nettoie les fichiers temporaires et les logs pour libérer de l'espace disque.
- **`restart_service.yaml`**: Redémarre un service `systemd` ou `init.d`.
- **`check_service_status.yaml`**: Vérifie le statut d'un service.
- **`execute_remote_script.yaml`**: Télécharge et exécute un script distant.

### Sauvegarde (`linux/backup`)

- **`backup_files.yaml`**: Crée une archive compressée (tar.gz) de fichiers et de répertoires.
- **`restore_files.yaml`**: Restaure des fichiers à partir d'une archive `tar.gz`.
- **`backup_database_mysql.yaml`**: Effectue une sauvegarde d'une base de données MySQL.
- **`restore_database_mysql.yaml`**: Restaure une base de données MySQL à partir d'un dump SQL.

### Reporting (`linux/reporting`)

- **`report_disk_usage.yaml`**: Génère un rapport sur l'utilisation de l'espace disque.
- **`report_memory_usage.yaml`**: Génère un rapport sur l'utilisation de la mémoire.
- **`list_running_processes.yaml`**: Liste tous les processus en cours d'exécution.
- **`audit_report.yaml`**: Génère un rapport d'audit de sécurité de base.

### Sécurité (`linux/security`)

- **`create_user.yaml`**: Crée un nouvel utilisateur.
- **`delete_user.yaml`**: Supprime un utilisateur et son répertoire personnel.
- **`add_user_to_group.yaml`**: Ajoute un utilisateur à un groupe.
- **`remove_user_from_group.yaml`**: Retire un utilisateur d'un groupe.
- **`change_user_password.yaml`**: Change le mot de passe d'un utilisateur.
- **`check_suid_guid.yaml`**: Recherche les fichiers avec les bits SUID/GUID.

---

## Templates Windows

Les templates pour Windows se trouvent dans le répertoire `templates/windows`.

### Déploiement (`windows/deployment`)

- **`deploy_iis_app.yaml`**: Déploie une application web sur un serveur IIS.
- **`deploy_windows_service.yaml`**: Déploie et installe un nouveau service Windows.
- **`deploy_docker_container.yaml`**: Déploie un conteneur Docker sur Windows.

### Maintenance (`windows/maintenance`)

- **`update_system.yaml`**: Installe les mises à jour Windows via PowerShell.
- **`cleanup_system.yaml`**: Nettoie les fichiers temporaires et les journaux d'événements.
- **`restart_service.yaml`**: Redémarre un service Windows.
- **`check_service_status.yaml`**: Vérifie le statut d'un service Windows.

### Sauvegarde (`windows/backup`)

- **`backup_files.yaml`**: Crée une archive compressée (ZIP) de fichiers et de répertoires.
- **`restore_files.yaml`**: Restaure des fichiers à partir d'une archive ZIP.
- **`backup_database_mssql.yaml`**: Effectue une sauvegarde d'une base de données Microsoft SQL Server.
- **`restore_database_mssql.yaml`**: Restaure une base de données Microsoft SQL Server.

### Reporting (`windows/reporting`)

- **`report_disk_usage.yaml`**: Génère un rapport sur l'utilisation de l'espace disque.
- **`report_memory_usage.yaml`**: Génère un rapport sur l'utilisation de la mémoire.
- **`list_running_processes.yaml`**: Liste tous les processus en cours d'exécution.
- **`security_baseline_analysis.yaml`**: Exécute une analyse de la ligne de base de sécurité.

### Sécurité (`windows/security`)

- **`create_user.yaml`**: Crée un nouvel utilisateur local.
- **`delete_user.yaml`**: Supprime un utilisateur local.
- **`add_user_to_group.yaml`**: Ajoute un utilisateur à un groupe local.
- **`remove_user_from_group.yaml`**: Retire un utilisateur d'un groupe local.
- **`change_user_password.yaml`**: Change le mot de passe d'un utilisateur local.
- **`check_open_ports.yaml`**: Vérifie les ports TCP ouverts.

---

## Anciens Templates

Les templates génériques suivants sont également disponibles :

- `ansible_job_template.yaml`
- `bash_job_template.yaml`
- `python_job_template.yaml`