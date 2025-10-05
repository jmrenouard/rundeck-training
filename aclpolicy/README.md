# Générateur de Fichier ACLPolicy pour Rundeck

Cet outil fournit une interface web pour générer dynamiquement des fichiers de politique de contrôle d'accès (`.aclpolicy`) pour Rundeck. Il est conçu pour être intuitif et vous guider dans la création de politiques complexes sans erreur de syntaxe.

## Fonctionnalités

- **Interface intuitive** : Construit avec Alpine.js et Tailwind CSS pour une expérience utilisateur fluide.
- **Génération en temps réel** : Visualisez le fichier YAML généré au fur et à mesure que vous remplissez le formulaire.
- **Support complet du format** : Permet de configurer toutes les sections principales d'une politique ACL : `description`, `context`, `for`, `by`, et `notBy`.
- **Politiques multiples** : Ajoutez et gérez plusieurs documents de politique dans un seul fichier, séparés par `---`.
- **Règles dynamiques** : Ajoutez, modifiez et supprimez des règles de ressources (`job`, `node`, etc.) et des actions (`allow`, `deny`) facilement.
- **Aucune installation requise** : La page est un simple fichier HTML (`index.html`) qui s'exécute directement dans le navigateur en utilisant des CDN pour ses dépendances.

## Utilisation

1.  Ouvrez le fichier `index.html` dans votre navigateur web.
2.  Utilisez le formulaire pour définir les différentes sections de votre politique ACL.
3.  Le code YAML correspondant sera généré automatiquement dans le panneau de droite.
4.  Copiez le code généré et collez-le dans un fichier `.aclpolicy` sur votre serveur Rundeck.

---

## Détails de l'Interface

L'interface est divisée en plusieurs sections qui correspondent à la structure d'un fichier `.aclpolicy`.

### Gestion des Politiques

- **Ajouter une politique** : Le bouton en haut à droite vous permet d'ajouter un nouveau bloc de politique. Chaque bloc sera séparé par `---` dans le fichier YAML final, ce qui correspond à un document YAML distinct.
- **Supprimer une politique** : Chaque bloc de politique a une icône de corbeille pour le supprimer.

### Champs d'une Politique

Chaque bloc de politique contient les champs suivants :

#### 1. `Description`

- **Objectif** : Une brève description de ce que fait la politique. Elle apparaîtra dans les logs de Rundeck et aide à la maintenance.
- **Exemple** : `Accès administrateur pour le projet "WebApp"`.

#### 2. `Contexte`

- **Objectif** : Définit la portée de la politique.
- **Champs** :
    - **Type** :
        - `project` : La politique s'applique à un ou plusieurs projets.
        - `application` : La politique s'applique à l'ensemble de l'application Rundeck (actions globales comme la création de projets).
    - **Valeur** :
        - Si le type est `project`, la valeur est une **expression régulière (regex)** qui correspond aux noms des projets. `.*` cible tous les projets. `WebApp` cible uniquement le projet nommé "WebApp".
        - Si le type est `application`, la valeur doit être `rundeck`.

#### 3. `Pour (for)`

- **Objectif** : C'est ici que vous définissez les règles d'autorisation pour des types de ressources spécifiques.
- **Utilisation** :
    - **Ajouter une ressource** : Crée un nouveau bloc pour un type de ressource (par exemple, `job`, `node`).
    - **Type de ressource** : Choisissez le type de ressource dans la liste déroulante (`job`, `node`, `project`, etc.).
    - **Ajouter une règle** : Dans chaque bloc de ressource, vous pouvez ajouter une ou plusieurs règles de correspondance.

##### Structure d'une Règle

- **Règle de correspondance** :
    - **Matcher** : Le type de comparaison (`equals`, `match`, `contains`, `subset`). Laissez vide si la règle doit s'appliquer à toutes les ressources de ce type.
    - **Propriété** : La propriété de la ressource à inspecter (ex: `name`, `group`, `tags`, `kind`).
    - **Valeur** : La valeur à comparer.
- **Actions** :
    - **Autoriser (allow)** : Liste des actions autorisées, séparées par une virgule (ex: `read,run,kill`).
    - **Refuser (deny)** : Liste des actions refusées, séparées par une virgule. `*` signifie toutes les actions.

**Exemple de règle `for`** :
Pour autoriser l'action `run` sur tous les jobs du groupe `ops`:
- Type de ressource : `job`
- Règle de correspondance :
    - Matcher: `match`
    - Propriété: `group`
    - Valeur: `ops/.*`
- Actions :
    - Autoriser (allow): `run`

#### 4. `Par (by)` et `Pas par (notBy)`

- **Objectif** : Spécifie à qui la politique s'applique (`by`) ou ne s'applique pas (`notBy`). `notBy` n'est utile que pour les actions `deny`.
- **Champs** (séparez les entrées multiples par une virgule) :
    - `username` : Noms d'utilisateurs. Peut être une regex.
    - `group` : Noms de groupes. Peut être une regex.
    - `urn` : Identifiant de ressource unique pour une correspondance exacte (ex: `user:admin`, `group:devs`).

**Exemple de `by`** :
Pour appliquer la politique au groupe `admins` et à l'utilisateur `jdoe` :
- `group`: `admins`
- `username`: `jdoe`