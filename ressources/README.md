# Générateur de Fichier de Ressources Rundeck

Cet outil fournit une interface web pour générer dynamiquement des fichiers de modèle de ressources (resource model) pour Rundeck au format YAML. Il est conçu pour simplifier la création et la gestion des définitions de nœuds sans avoir à écrire le YAML manuellement.

## Contexte

Dans Rundeck, un projet s'appuie sur un fichier de modèle de ressources pour définir l'ensemble des nœuds sur lesquels des commandes ou des jobs peuvent être exécutés. Ce fichier, généralement au format YAML, répertorie chaque nœud avec ses attributs de connexion (nom d'hôte, nom d'utilisateur) et des métadonnées descriptives (tags, système d'exploitation, etc.).

La maintenance manuelle de ce fichier peut être fastidieuse et sujette à des erreurs de syntaxe, en particulier dans les environnements comportant de nombreux nœuds. Ce générateur vise à résoudre ce problème.

## Fonctionnalités

- **Interface Graphique Intuitive** : Ajoutez, modifiez ou supprimez des nœuds via un formulaire simple.
- **Validation Implicite** : La structure générée respecte le format requis par Rundeck.
- **Attributs Standard et Personnalisés** : Prend en charge les attributs Rundeck par défaut (`nodename`, `hostname`, `username`, `osFamily`, etc.) et permet d'ajouter des attributs personnalisés.
- **Génération en Temps Réel** : Le code YAML est mis à jour instantanément à chaque modification.
- **Copie Facile** : Un bouton permet de copier le YAML généré dans le presse-papiers.
- **Auto-contenu** : L'outil est un simple fichier `index.html` qui s'exécute dans n'importe quel navigateur web moderne, sans nécessiter de backend.

## Comment Utiliser

1.  **Ouvrir `index.html`** : Lancez le fichier `index.html` dans votre navigateur.
2.  **Ajouter un Nœud** :
    *   Cliquez sur le bouton "Ajouter un Nœud".
    *   Remplissez les champs requis comme `nodename`, `hostname` et `username`.
    *   Ajoutez des tags (séparés par des virgules) et d'autres attributs optionnels.
    *   Pour ajouter des attributs personnalisés (par exemple, `app-port: 8080`), utilisez la section "Attributs Personnalisés".
3.  **Gérer les Nœuds** :
    *   Vous pouvez modifier les informations de chaque nœud directement dans les champs.
    *   Cliquez sur le bouton "Supprimer" à côté d'un nœud pour le retirer de la liste.
4.  **Importer des Données (Optionnel)** :
    *   Si vous avez un fichier YAML existant, vous pouvez le coller dans la zone de texte "Importer YAML" et cliquer sur "Importer" pour peupler l'interface.
5.  **Récupérer le YAML** :
    *   Le YAML correspondant à votre configuration est affiché dans la zone de texte en bas de la page.
    *   Cliquez sur "Copier YAML" pour le copier dans votre presse-papiers.
    *   Enregistrez ce contenu dans un fichier (par exemple, `resources.yml`) dans le répertoire de votre projet Rundeck.

## Structure du Fichier de Ressources YAML (Rappel)

Le format YAML pour les ressources Rundeck peut être une séquence ou une carte (map). Cet outil génère une carte, qui est souvent plus lisible.

### Définition d'un Nœud

Un nœud est défini par une carte d'attributs.

**Attributs Requis :**

*   `nodename`: Identifiant unique du nœud.
*   `hostname`: Adresse IP ou nom d'hôte pour la connexion (peut inclure un port, ex: `mon-hote:2222`).
*   `username`: Nom d'utilisateur pour la connexion SSH.

**Attributs Optionnels Courants :**

*   `description`: Description textuelle du nœud.
*   `tags`: Liste de tags séparés par des virgules, utilisés pour filtrer les nœuds.
*   `osFamily`, `osArch`, `osName`, `osVersion`: Informations sur le système d'exploitation.
*   `ssh-key-storage-path`: Chemin vers une clé SSH dans le Keystore de Rundeck.

**Attributs Personnalisés :**

Vous pouvez ajouter n'importe quel couple clé-valeur pour stocker des informations supplémentaires sur un nœud.

### Exemple de YAML Généré

```yaml
Venkman.local:
  nodename: Venkman.local
  hostname: Venkman.local
  username: greg
  description: Rundeck server node
  osArch: x86_64
  osFamily: unix
  osName: Mac OS X
  osVersion: 10.6.6
  tags: 'rundeck, server'
Homestar.local:
  nodename: Homestar.local
  hostname: Homestar.local
  username: greg
  description: The production redis server.
  tags: 'redis_server, production'
  app-port: 6379
```