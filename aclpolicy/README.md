# Générateur de Fichier `ACLPolicy` pour Rundeck

Cet outil est un générateur web conçu pour simplifier la création de fichiers de politique de contrôle d'accès (`.aclpolicy`) pour **Rundeck**. Créer des ACLs manuellement peut être complexe et source d'erreurs ; cet utilitaire fournit une interface graphique pour construire des politiques robustes de manière intuitive.

## Le Rôle des `ACLPolicy` dans Rundeck

Dans Rundeck, les `ACLPolicy` sont le mécanisme central qui définit **qui** a le droit de faire **quoi**. Elles permettent de mettre en place une gouvernance fine des accès, en contrôlant les permissions pour chaque action, projet, job, nœud, etc. Une mauvaise configuration peut entraîner des failles de sécurité ou empêcher les utilisateurs légitimes de travailler. Cet outil a pour but de rendre ce processus plus sûr et plus simple.

## Fonctionnalités

- **Interface Guidée** : Construit avec **Alpine.js** et **Tailwind CSS** pour une expérience fluide et réactive.
- **Génération en Temps Réel** : Le fichier YAML se met à jour instantanément dans le panneau de droite à chaque modification.
- **Support Complet du Format** : Configurez toutes les sections d'une politique : `description`, `context` (projet ou application), `for` (règles sur les ressources), `by` (à qui s'applique la politique), et `notBy`.
- **Politiques Multiples** : Gérez plusieurs documents de politique dans un seul fichier, séparés par `---`, pour une meilleure organisation.
- **Règles Dynamiques** : Ajoutez, modifiez et supprimez des règles de ressources (`job`, `node`, etc.) et des actions (`allow`, `deny`) en quelques clics.
- **Import YAML** : Collez un fichier `.aclpolicy` existant pour que le formulaire se remplisse automatiquement, facilitant ainsi la modification de politiques existantes.
- **Internationalisation (FR/EN)** : L'interface est disponible en Français et en Anglais pour une meilleure accessibilité.
- **Zéro Installation** : La page est un simple fichier `index.html` autonome qui s'exécute dans n'importe quel navigateur moderne.

## Utilisation

1.  Ouvrez le fichier `index.html` dans votre navigateur.
2.  Utilisez le formulaire pour construire votre politique. Commencez par définir le `contexte` (un projet ou toute l'application).
3.  Ajoutez des blocs de règles dans la section `Pour (for)` pour spécifier les ressources et les permissions.
4.  Définissez à qui la politique s'applique dans la section `Par (by)`.
5.  Le code YAML valide est généré automatiquement. Copiez-le et collez-le dans un fichier avec l'extension `.aclpolicy` dans le répertoire de configuration de votre serveur Rundeck.

---

## Détails de l'Interface

### Gestion des Politiques

- **Ajouter une politique** : Idéal pour séparer logiquement les permissions (ex: une politique pour les développeurs, une autre pour les opérateurs). Chaque politique est un document YAML distinct.
- **Supprimer une politique** : Chaque bloc de politique peut être supprimé individuellement.

### Champs d'une Politique

#### 1. `Description`

- **Objectif** : Une phrase décrivant le but de la politique. Essentiel pour la maintenance.
- **Exemple** : `Accès en lecture seule pour les auditeurs sur le projet "Compliance"`.

#### 2. `Contexte`

- **Objectif** : Définit la portée de la politique.
- **Champs** :
    - **Type** : `project` (s'applique à un ou plusieurs projets) ou `application` (s'applique globalement, pour des actions comme la gestion des utilisateurs ou des projets).
    - **Valeur** :
        - Pour `project` : Une **expression régulière (regex)** qui correspond aux noms des projets. Ex: `WebApp` pour un projet unique, `Projet-.*` pour tous les projets commençant par "Projet-".
        - Pour `application` : Doit être `rundeck`.

#### 3. `Pour (for)`

- **Objectif** : Le cœur de l'ACL. C'est ici que vous définissez les permissions sur les ressources.
- **Structure** :
    - **Type de ressource** : La ressource à protéger (`job`, `node`, `project`, `storage`, etc.).
    - **Règle de correspondance** : Permet de filtrer les ressources.
        - **Matcher** : Comment comparer (`equals`, `match`, `contains`). Laissez vide pour cibler toutes les ressources du type choisi.
        - **Propriété** : L'attribut de la ressource à inspecter (`name`, `group`, `tags`).
        - **Valeur** : La valeur à comparer.
    - **Actions** :
        - **Autoriser (allow)** / **Refuser (deny)** : La liste des permissions (`read`, `run`, `kill`, `create`). `*` signifie toutes les actions.

**Exemple Pratique** :
Pour autoriser les membres du groupe `dev` à exécuter des jobs dans le groupe `dev-jobs` du projet `WebApp` :
- Contexte : `project: WebApp`
- Pour :
    - Type de ressource : `job`
    - Règle : `match`, `group`, `dev-jobs/.*`
    - Actions : `allow: [run, read]`
- Par :
    - `group: dev`

#### 4. `Par (by)` et `Pas par (notBy)`

- **Objectif** : Spécifie les sujets de la politique.
- **Champs** (séparer par des virgules pour plusieurs entrées) :
    - `username` : Noms d'utilisateurs (supporte les regex).
    - `group` : Noms de groupes (supporte les regex).
    - `urn` : Identifiant unique (moins courant).
- **Note** : `notBy` est principalement utilisé avec `deny` pour créer des exceptions.