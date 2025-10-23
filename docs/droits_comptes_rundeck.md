# 📚 Guide Pratique : Gestion des Droits et Comptes Utilisateurs dans Rundeck avec les Politiques ACL

## 🎯 L'Objectif : Le Modèle de Droits

Nous allons définir 5 profils d'utilisateurs et créer les fichiers de politique (`.aclpolicy`) correspondants.

1.  **Admin généraux** : Contrôle total.
2.  **Lecture seule (Globale)** : Voit tout, ne touche à rien.
3.  **Administrateur de Projet** : Contrôle total d'un projet spécifique.
4.  **Développeur de Projet** : Gère les jobs (création, exécution) d'un projet.
5.  **Lecture seule (Projet)** : Voit tout dans un projet spécifique, mais ne touche à rien.

Commençons par une base essentielle : la nomenclature.

-----

## 🏷️ Proposition de Nomenclature de Nommage

Pour garder les choses claires et maintenables, il est crucial d'adopter une convention de nommage. Puisque les politiques ACL s'appliquent le plus souvent à des **groupes**, je vous propose la nomenclature suivante pour vos groupes (que vous créerez dans votre `realm.properties` ou que vous mapperez via LDAP/SSO) :

  * `grp_rundeck_admin` : Pour les administrateurs généraux (Profil 1).
  * `grp_rundeck_readonly_global` : Pour la lecture seule globale (Profil 2).
  * `grp_[NomProjet]_admin` : Pour les admins d'un projet (Profil 3).
      * *Exemple :* `grp_WebApp_admin`
  * `grp_[NomProjet]_developer` : Pour les développeurs du projet (Profil 4).
      * *Exemple :* `grp_WebApp_developer`
  * `grp_[NomProjet]_readonly` : Pour la lecture seule d'un projet (Profil 5).
      * *Exemple :* `grp_WebApp_readonly`

Cette structure est claire : `grp` pour groupe, `[contexte]` (soit `rundeck` pour global, soit le nom du projet), et `[rôle]`.

-----

## 🧠 Théorie : Comment fonctionne une ACL Rundeck ?

Chaque fichier `.aclpolicy` (placé dans `/etc/rundeck/` ou `C:\rundeck\etc`) contient une ou plusieurs "règles". Rundeck les lit toutes et les combine pour décider si une action est autorisée ou non.

Une règle se compose de 4 parties principales :

1.  `description`: (Optionnel) Une explication lisible de ce que fait la règle.
2.  `context`: Définit la portée de la règle.
      * `application: 'rundeck'`: Portée "Système" (actions globales, liste des projets).
      * `project: 'NomDuProjet'`: Portée "Projet" (actions à l'intérieur d'un projet spécifique).
3.  `by`: Définit **QUI** est concerné par la règle (un `group`, un `user`, ou une `urn`). Nous utiliserons `group`
4.  `for`: Définit **QUOI** (la ressource) et `allow` ou `deny` (l'action).
      * `resource`: Le type d'objet (ex: `project`, `job`, `node`).
      * `allow`: Une liste d'actions autorisées (ex: `read`, `run`, `create`, `admin`).
      * `deny`: Une liste d'actions interdites (Deny l'emporte toujours sur Allow).

L'action `admin` est un joker qui signifie "toutes les actions". L'action `read` est un joker pour toutes les actions de lecture (`view`, `list`, etc.).

Maintenant, passons à la pratique \!

-----

## 🛠️ Les Modèles de Politiques ACL

Voici les fichiers de politique pour chaque profil. Je vous recommande de créer un fichier `.aclpolicy` distinct pour chaque *groupe* ou *rôle* logique. C'est plus simple à gérer.

### 1° Admin généraux

  * **Description :** Contrôle total sur l'instance Rundeck. Peut tout voir, tout configurer, créer/supprimer des projets, gérer les utilisateurs et la configuration système.
  * **Fichier :** `admin_global.aclpolicy`

<!-- end list -->

```yaml
# Fichier: admin_global.aclpolicy
description: "Profil 1: Admin généraux - Accès total."
by:
  group: grp_rundeck_admin

context:
  application: 'rundeck' # Contexte Système
for:
  system:
    - allow: [admin] # 'admin' = joker pour TOUTES les actions système
  project:
    - match:
        name: '.*' # '.*' = Regex pour TOUS les projets
      allow: [admin] # 'admin' = joker pour TOUTES les actions projet
```

### 2° Lecture seule (Globale)

  * **Description :** Peut se connecter, voir la liste de tous les projets, et dans chaque projet, voir les jobs, l'historique des exécutions, les nœuds, et les rapports. Ne peut rien exécuter, modifier ou créer.
  * **Fichier :** `readonly_global.aclpolicy`

<!-- end list -->

```yaml
# Fichier: readonly_global.aclpolicy
description: "Profil 2: Lecture seule globale sur tous les projets."
by:
  group: grp_rundeck_readonly_global

context:
  application: 'rundeck' # Contexte Système
for:
  system:
    - allow: [read] # 'read' permet de lister les projets et voir l'activité
  project:
    - match:
        name: '.*' # Pour TOUS les projets
      allow: [read] # 'read' permet de lire jobs, nœuds, historique, etc.
```

### 3° Administrateur d'un projet

  * **Description :** Contrôle total sur **un seul** projet (ex: "WebApp"). Peut configurer le projet, gérer les nœuds, créer/modifier/exécuter tous les jobs, et voir l'historique de ce projet. Ne peut pas voir les autres projets (sauf s'ils ont un autre groupe).
  * **Fichier :** `project_webapp_admin.aclpolicy` (N'oubliez pas de renommer le fichier et le groupe \!)

<!-- end list -->

```yaml
# Fichier: project_webapp_admin.aclpolicy
description: "Profil 3: Admin du projet 'WebApp'."
by:
  group: grp_WebApp_admin # <-- Remplacer 'WebApp' par le nom du projet

# 1. Droit de voir la liste des projets pour pouvoir sélectionner le leur
context:
  application: 'rundeck'
for:
  system:
    - allow: [read] # Juste assez pour lister les projets

# 2. Droits d'administration sur LEUR projet
context:
  project: 'WebApp' # <-- Remplacer 'WebApp' par le nom du projet
for:
  project:
    - allow: [admin] # 'admin' donne tous les droits DANS ce projet
```

### 4° Développeur de jobs (Projet)

  * **Description :** Le profil "classique". Peut voir les ressources du projet ("WebApp"), mais surtout créer, modifier, supprimer, exécuter et tuer les jobs de ce projet.
  * **Fichier :** `project_webapp_developer.aclpolicy`

<!-- end list -->

```yaml
# Fichier: project_webapp_developer.aclpolicy
description: "Profil 4: Développeur sur le projet 'WebApp'."
by:
  group: grp_WebApp_developer # <-- Remplacer 'WebApp'

# 1. Droit de voir la liste des projets
context:
  application: 'rundeck'
for:
  system:
    - allow: [read]

# 2. Droits spécifiques dans le projet
context:
  project: 'WebApp' # <-- Remplacer 'WebApp'
for:
  project:
    - allow: [read] # Droit de lecture de base (voir nœuds, historique...)
  job:
    # CRUD complet sur les jobs + exécution
    - allow: [create, read, update, delete, run, kill]
  node:
    # Requis pour que les jobs s'exécutent sur les nœuds
    - allow: [read, run] 
```

### 5° Lecture seule (Projet)

  * **Description :** Identique au profil 2 (Lecture seule globale), mais limité à **un seul** projet (ex: "WebApp"). Utile pour un manager ou une équipe support qui a besoin de voir ce qui se passe sans risque d'agir.
  * **Fichier :** `project_webapp_readonly.aclpolicy`

<!-- end list -->

```yaml
# Fichier: project_webapp_readonly.aclpolicy
description: "Profil 5: Lecture seule sur le projet 'WebApp'."
by:
  group: grp_WebApp_readonly # <-- Remplacer 'WebApp'

# 1. Droit de voir la liste des projets
context:
  application: 'rundeck'
for:
  system:
    - allow: [read]

# 2. Droit de lecture DANS le projet
context:
  project: 'WebApp' # <-- Remplacer 'WebApp'
for:
  project:
    - allow: [read] # 'read' couvre la lecture de tout (jobs, nœuds, etc.)
```

-----

## ✅ Résumé et Prochaines Étapes

Nous avons défini une nomenclature de groupes claire et créé 5 politiques ACL granulaires qui répondent parfaitement à vos besoins.

**Pour les utiliser :**

1.  Créez ces fichiers `.aclpolicy` dans votre répertoire de configuration Rundeck (`/etc/rundeck/`).
2.  Assurez-vous que vos utilisateurs appartiennent aux bons groupes (ex: `grp_WebApp_developer`).
3.  Testez \! Connectez-vous avec un utilisateur de test pour chaque profil et vérifiez que les permissions et les restrictions s'appliquent comme prévu.
