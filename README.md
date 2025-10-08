![rundeck-training](banner.png)
# Projet d'Automatisation et de Déploiement de Rundeck

Ce projet est une boîte à outils complète conçue pour le déploiement, la configuration et la gestion d'un environnement **Rundeck** robuste et production-ready. Il est structuré en plusieurs composants, chacun abordant un aspect spécifique de l'automatisation et de l'infrastructure.

## Composants Principaux

### [Ansible](./ansible/README.md)
Ce répertoire est le cœur de l'automatisation. Il contient des **playbooks et rôles Ansible** conçus pour déployer l'ensemble de la stack applicative :
- **Java**
- **MySQL** (Base de données pour Rundeck)
- **Rundeck** (L'orchestrateur d'automatisation)
- **Keycloak** (Pour la gestion centralisée des identités et des accès - SSO)
- **MinIO** (Stockage objet S3 pour les logs et les artéfacts)

Chaque rôle est modulaire et configurable, suivant les meilleures pratiques Ansible.

### [Docker](./docker/README.md)
Pour un démarrage rapide et un environnement de développement reproductible, ce répertoire fournit des configurations **Docker Compose** et **Docker Swarm**. Vous pouvez lancer la stack complète localement en quelques minutes, idéal pour les tests, le développement de jobs ou la formation.

### [Scripts](./scripts/README.md)
Une collection de **scripts Bash** robustes pour l'installation, la configuration et la maintenance de la stack sur des systèmes **Ubuntu**. Ces scripts sont parfaits pour une installation "bare-metal" ou pour des scénarios où Ansible n'est pas disponible. Ils incluent des routines de **sauvegarde et de restauration** pour Rundeck et MinIO.

### [Templates](./templates/README.md)
Une bibliothèque riche de plus de **40 templates de jobs Rundeck** au format YAML. Ces templates prêts à l'emploi couvrent un large éventail de cas d'usage pour les plateformes **Linux et Windows** :
- Déploiement d'applications
- Intégration avec MinIO/S3
- Maintenance système (mises à jour, nettoyage)
- Opérations de sauvegarde et restauration
- Reporting et notifications
- Gestion de la sécurité

## Utilitaires

### [aclpolicy](./aclpolicy/README.md)
Un générateur web pour les fichiers `ACLPolicy` de Rundeck. Cet outil en **HTML/JS avec Alpine.js** simplifie la création de politiques de contrôle d'accès complexes en fournissant une interface graphique intuitive, réduisant ainsi les erreurs de syntaxe.

### [ressources](./ressources/README.md)
Un générateur web pour les fichiers de modèle de ressources (`resources.yml`). Cet outil en **HTML/JS avec Alpine.js et js-yaml** facilite la définition de vos nœuds cibles, avec leurs attributs et tags, pour une gestion d'inventaire claire et centralisée.

### [jobs](./jobs/README.md)
Un générateur web pour créer des définitions de jobs Rundeck. Cet outil en **HTML/JS avec Alpine.js et js-yaml** permet de construire des jobs complexes, notamment ceux qui font appel à des playbooks **Ansible**, en remplissant un simple formulaire. Il génère le YAML correspondant, prêt à être importé dans Rundeck.