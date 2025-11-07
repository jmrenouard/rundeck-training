## Fichier `framework.properties`

⚙️ **Description Générale**
[cite_start]Le fichier `framework.properties` est un fichier de configuration fondamental utilisé par les outils en ligne de commande (CLI) et les services principaux de Rundeck[cite: 2274]. [cite_start]Il est normalement créé lors de l'installation initiale[cite: 2274].

---
📊 **Paramètres Principaux**
Ces paramètres définissent l'identité et les chemins de base du serveur Rundeck.

| Paramètre | Description | Défaut | Source(s) |
| :--- | :--- | :--- | :--- |
| `framework.server.hostname` | Nom d'hôte du nœud serveur Rundeck. | [cite_start]N/A | [cite: 2274] |
| `framework.server.name` | Nom (identité) du nœud serveur Rundeck. | [cite_start]N/A | [cite: 2274] |
| `framework.projects.dir` | Chemin vers le répertoire contenant les répertoires des projets Rundeck. | [cite_start]`$RDECK_BASE/projects` | [cite: 2274, 2275] |
| `framework.var.dir` | Répertoire de base pour les fichiers temporaires (temp) et les sorties (output) utilisés par le serveur et les outils CLI. | [cite_start]`$RDECK_BASE/var` | [cite: 2275] |
| `framework.logs.dir` | Répertoire pour les fichiers journaux (logs) écrits par les services principaux et les exécutions de Jobs du serveur Rundeck. | [cite_start]`$RDECK_BASE/var/logs` | [cite: 2275, 2208] |
| `framework.rundeck.url` | URL de base pour le serveur Rundeck. | [cite_start]N/A | [cite: 2275] |
| `framework.server.username` | Nom d'utilisateur pour la connexion au serveur Rundeck (principalement utilisé par les outils CLI). | [cite_start]N/A | [cite: 2276] |
| `framework.server.password` | Mot de passe pour la connexion au serveur Rundeck (principalement utilisé par les outils CLI). | [cite_start]N/A | [cite: 2277] |

---
💻 **Paramètres de Connexion SSH**
[cite_start]Ces paramètres configurent le comportement SSH global par défaut pour l'exécution des tâches sur les nœuds distants[cite: 2276].

| Paramètre | Description | Défaut | Source(s) |
| :--- | :--- | :--- | :--- |
| `framework.ssh.keypath` | Chemin vers le fichier de clé privée SSH utilisé pour les connexions SSH. | [cite_start]N/A | [cite: 2276] |
| `framework.ssh.user` | Nom d'utilisateur par défaut pour les connexions SSH, s'il n'est pas surchargé par une valeur spécifique au Nœud. | [cite_start]N/A | [cite: 2276] |
| `framework.ssh-connection-timeout` | Délai d'attente (en millisecondes) pour l'établissement des connexions SSH. | [cite_start]`0` (pas de délai) | [cite: 2276] |
| `framework.ssh-command-timeout` | Délai d'attente (en millisecondes) pour l'exécution des commandes SSH. | [cite_start]`0` (pas de délai) | [cite: 2276] |

---
⚙️ **Autres Paramètres**

| Paramètre | Description | Défaut | Source(s) |
| :--- | :--- | :--- | :--- |
| `framework.log.dispatch.console.format` | Format par défaut pour la journalisation (non-terse) des exécutions de nœuds lancées par l'outil CLI `dispatch`. | [cite_start]N/A | [cite: 2277] |
| `execution.script.tokenexpansion.enabled` | Détermine si l'expansion des tokens (variables contextuelles, ex: `@option.myoption@`) dans les scripts "inline" est activée. | [cite_start]`true` | [cite: 2277] |
| `communityNews.disabled` | Désactive la récupération externe du flux "Community News". | [cite_start]`false` | [cite: 2278] |

---
### 🔑 Tokens d'API Statiques
[cite_start]Vous pouvez définir un emplacement pour un fichier de propriétés contenant des tokens d'authentification API statiques[cite: 2278].

* `rundeck.tokens.file=/etc/rundeck/tokens.properties`
    * [cite_start]Le fichier `tokens.properties` doit contenir des entrées au format `username: token_string` (ou `username: token_string,role1,role2...` depuis la version 3.3.x)[cite: 2278].

### 🌍 Variables d'Exécution Globales
[cite_start]Vous pouvez définir des variables globales qui seront disponibles dans tous les contextes d'exécution (pour tous les projets)[cite: 2279].

* `framework.globals.X=Y`
    * [cite_start]Ajoute une variable `X` avec la valeur `Y`, accessible dans les scripts et commandes via `${globals.X}`[cite: 2279].
    * [cite_start]Ces variables peuvent être surchargées au niveau du projet dans le fichier `project.properties`[cite: 2279].
