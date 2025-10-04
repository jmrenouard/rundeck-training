# Projet d'Automatisation et de Déploiement de Rundeck

Ce projet fournit une collection complète d'outils pour déployer, configurer et gérer un environnement Rundeck. Il est divisé en plusieurs répertoires, chacun se concentrant sur un aspect spécifique de l'automatisation.

## Répertoires

### [Ansible](./ansible/README.md)
Ce répertoire contient les playbooks et les rôles Ansible pour automatiser le déploiement de la stack Rundeck (Java, MySQL, Rundeck, Keycloak).

### [Docker](./docker/README.md)
Vous trouverez ici les configurations Docker pour lancer rapidement un environnement de développement local ou de production avec Docker Compose et Docker Swarm.

### [Scripts](./scripts/README.md)
Une collection de scripts Bash pour une installation manuelle et automatisée de la stack Rundeck sur un système Ubuntu.

### [Templates](./templates/README.md)
Contient des templates de jobs Rundeck au format YAML, prêts à être importés, pour exécuter des tâches avec Ansible, Bash ou Python.