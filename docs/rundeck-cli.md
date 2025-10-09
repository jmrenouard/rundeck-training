# **Guide de la CLI Rundeck (rd)**

Ce document est une référence complète des commandes rd, organisées par thématiques pour un apprentissage plus simple. Chaque section est enrichie avec des contextes d'utilisation et des exemples avancés pour une meilleure compréhension.

[**Guide de la CLI Rundeck (rd)	1**](#heading=)

[Gestion des Projets (projects)	1](#heading=)

[Gestion des Jobs (jobs)	2](#heading=)

[Lancement et Exécution (run & adhoc)	3](#heading=)

[Suivi des Exécutions (executions)	4](#heading=)

[Gestion des Nœuds (nodes)	5](#heading=)

[Administration Système (system & tokens)	6](#heading=)

[Gestion des ACL (acl)	7](#heading=)

## **Gestion des Projets (projects)**

Les projets sont les conteneurs principaux dans Rundeck. Ils isolent les jobs, les nœuds, les clés et les configurations, ce qui est essentiel pour organiser le travail par environnement (dev, prod), par équipe ou par application.

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd projects list | Affiche la liste de tous les projets sur le serveur Rundeck. | rd projects list Très utile pour avoir une vue d'ensemble rapide ou pour scripter des actions sur tous les projets. |
| rd projects create | Crée un nouveau projet. | rd projects create \-p mon-nouveau-projet Parfait pour automatiser la mise en place d'un nouvel environnement de déploiement via un script. |
| rd projects delete | Supprime un projet existant. **Attention, cette action est irréversible.** | rd projects delete \-p projet-a-supprimer |
| rd projects info | Affiche les informations détaillées d'un projet. | rd projects info \-p mon-projet Permet de vérifier rapidement la configuration d'un projet, comme sa source de nœuds. |
| rd projects archives export | Exporte un projet entier (jobs, historique, config) dans une archive .zip. | rd projects archives export \-p mon-projet \-f /tmp/backup-$(date \+%F).zip Indispensable pour les sauvegardes, la migration d'un projet d'un serveur Rundeck à un autre, ou l'archivage. |
| rd projects archives import | Importe un projet depuis une archive. | rd projects archives import \-p mon-projet-restaure \-f /tmp/backup.zip Utilisé pour la restauration après un sinistre ou pour dupliquer un projet afin de créer un nouvel environnement. |

## **Gestion des Jobs (jobs)**

Les jobs sont le cœur de Rundeck : des tâches ou des workflows à exécuter. Leur définition en format texte (YAML/XML) les rend parfaitement adaptés à la gestion de version (Git) et à la philosophie "Job-as-Code".

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd jobs list | Liste tous les jobs d'un projet et peut exporter leurs définitions. | rd jobs list \-p mon-projet \-f jobs.yaml L'export en fichier est la base du "Job-as-Code". Vous versionnez ce fichier dans Git pour suivre les modifications. |
| rd jobs load | Charge (importe) des définitions de jobs depuis un fichier. | rd jobs load \-p mon-projet \-f jobs.yaml \-d update Idéal dans un pipeline CI/CD pour déployer les modifications de jobs automatiquement depuis Git. |
| rd jobs info | Affiche les informations détaillées d'un job (ID, groupe, etc.). | rd jobs info \--job "Mon Groupe/Mon Job" \-p mon-projet Utile pour récupérer l'UUID stable d'un job, qui est préférable à son nom dans les scripts pour éviter les erreurs si le job est renommé. |
| rd jobs enable | Active l'exécution d'un job. | rd jobs enable \-i \<ID\_DU\_JOB\> |
| rd jobs disable | Désactive l'exécution d'un job. | rd jobs disable \-j "Groupe/Job" Pratique pour retirer temporairement un job pendant une maintenance, sans le supprimer. |

## **Lancement et Exécution (run & adhoc)**

Ces commandes permettent de lancer des tâches, soit planifiées (jobs), soit ponctuelles (adhoc).

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd run | Exécute un job spécifique par son ID ou son nom. | rd run \-j "Deploy/WebApp" \-p Production \-f Le \-f (follow) est crucial pour les lancements manuels, car il vous permet de voir la sortie en temps réel. |
| rd run \-- \-option\_val | Passe des options (arguments) à un job. | rd run \-j "Deploy/WebApp" \-- \-git\_branch "feature-xyz" \-deploy\_env "staging" Rend les jobs réutilisables et dynamiques. C'est la méthode standard pour intégrer Rundeck avec d'autres outils comme Jenkins. |
| rd adhoc | Exécute une commande shell sur un ensemble de nœuds. | rd adhoc \-p web-prod \-F 'tags: webserver' \-- "df \-h /" Extrêmement puissant pour le diagnostic rapide ou des actions simples sur un parc de machines, sans avoir besoin de créer un job formel. |

## **Suivi des Exécutions (executions)**

Une fois un job lancé, son exécution peut être suivie, inspectée et gérée.

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd executions list | Liste toutes les exécutions en cours dans un projet. | rd executions list \-p mon-projet |
| rd executions query | Recherche dans l'historique des exécutions selon des critères. | rd executions query \-p prod \-s failed \--recent 24h Essentiel pour le reporting et le débogage. Permet de trouver rapidement les échecs récents pour analyse. |
| rd executions follow | Affiche la sortie d'une exécution (en cours ou terminée). | rd executions follow \-e \<ID\_EXECUTION\> La commande de choix pour déboguer une exécution passée en ré-affichant sa sortie complète. |
| rd executions info | Affiche les détails d'une exécution. | rd executions info \-e \<ID\_EXECUTION\> Permet de vérifier qui a lancé un job, quand, et avec quelles options. |
| rd executions kill | Tente d'arrêter une exécution en cours. | rd executions kill \-e \<ID\_EXECUTION\> Une sécurité nécessaire pour stopper un processus long ou qui se comporte mal. |

## **Gestion des Nœuds (nodes)**

Les nœuds sont les machines cibles sur lesquelles Rundeck exécute des commandes ou des jobs.

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd nodes list | Liste les nœuds d'un projet, en utilisant la syntaxe de filtre de Rundeck. | rd nodes list \-p prod \-F 'tags: web+db \!tags: maintenance' La commande clé pour vérifier que votre inventaire de nœuds (statique ou dynamique via AWS, Ansible, etc.) est correctement chargé. |
| rd nodes list \--outformat | Personnalise le format de sortie. | rd nodes list \-p prod \--outformat "%nodename %osFamily %ipaddress" Permet de créer des rapports simples ou d'enchaîner avec d'autres outils en ligne de commande. |

## **Administration Système (system & tokens)**

Commandes pour interagir avec l'état global du serveur Rundeck, essentielles pour la maintenance et la sécurité.

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd system info | Affiche les informations système de l'instance Rundeck. | rd system info Utile pour vérifier la version de Rundeck, l'état de l'ordonnanceur, etc. |
| rd system mode active | Met le serveur en mode "actif" (il peut exécuter des jobs). | rd system mode active |
| rd system mode passive | Met le serveur en mode "passif" (n'exécute plus de jobs). | rd system mode passive Crucial avant une opération de maintenance ou une mise à jour pour s'assurer qu'aucun job ne démarre. |
| rd tokens create | Crée un jeton d'API pour un utilisateur. | rd tokens create \-u jenkins-ci \--roles api\_user,deploy La méthode sécurisée pour donner un accès programmatique à Rundeck, en limitant les droits via des rôles. |
| rd tokens list | Liste les jetons d'un utilisateur. | rd tokens list \-u admin |
| rd tokens delete | Supprime un jeton par son ID. | rd tokens delete \-i \<ID\_TOKEN\> |

## **Gestion des ACL (acl)**

ACL (Access Control List) gère les permissions. C'est une section avancée mais très puissante pour la sécurité.

| Commande | Description | Exemple d'utilisation et Contexte |
| :---- | :---- | :---- |
| rd acl validate | Valide la syntaxe d'un fichier de politique ACL. | rd acl validate \-f /etc/rundeck/mon\_acl.aclpolicy À intégrer dans votre pipeline CI/CD pour vérifier les ACLs avant de les déployer et éviter les erreurs de syntaxe. |
| rd acl test | Teste si une action serait autorisée par les politiques en place. | rd acl test \-c project \-p P1 \-g dev \--job "job1" \-a run L'outil de débogage parfait pour comprendre pourquoi un utilisateur n'a pas accès à une ressource. |
| rd acl create | Aide à générer interactivement une politique ACL en YAML. | rd acl create \-c project \-p '.\*' \-g api\_users \-a read \--job '.\*' Très pratique pour les administrateurs qui débutent avec la syntaxe complexe des ACLs. |
