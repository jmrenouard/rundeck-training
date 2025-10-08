# Générateur de Fichier de Ressources Rundeck

Cet outil est un générateur web conçu pour simplifier la création et la maintenance des fichiers de **modèle de ressources** (`resource model`) pour Rundeck. Il offre une interface graphique pour définir vos nœuds, évitant ainsi l'édition manuelle de fichiers YAML, qui peut être fastidieuse et source d'erreurs.

## L'Importance du Modèle de Ressources

Dans Rundeck, le modèle de ressources est le **catalogue de votre infrastructure**. C'est un fichier (généralement `resources.yml`) qui définit tous les serveurs, conteneurs ou services (`nœuds`) sur lesquels Rundeck peut exécuter des commandes et des jobs.

Un modèle de ressources bien défini est crucial car il permet :
- De **cibler précisément** les jobs (ex: "exécuter ce script sur tous les serveurs web de production").
- D'**enrichir les workflows** en passant des métadonnées spécifiques à un nœud (ex: l'IP d'une base de données, un port applicatif) directement dans un script.
- De **maintenir un inventaire** centralisé et cohérent de votre parc.

## Fonctionnalités

- **Interface Graphique Intuitive** : Ajoutez, modifiez et supprimez des nœuds via un formulaire simple et clair.
- **Génération YAML en Temps Réel** : Visualisez le code YAML se construire instantanément à chaque modification.
- **Support des Attributs Standard et Personnalisés** : Gère les attributs par défaut de Rundeck (`nodename`, `hostname`, `osFamily`, etc.) et vous permet d'ajouter n'importe quelle métadonnée personnalisée.
- **Import de Données Existantes** : Collez un YAML existant pour peupler automatiquement le formulaire et le modifier facilement.
- **Internationalisation** : L'interface est disponible en **Français** et en **Anglais**.
- **Zéro Installation** : L'outil est un simple fichier `index.html` qui s'exécute dans n'importe quel navigateur, utilisant des CDN pour ses dépendances (Alpine.js, Tailwind CSS, js-yaml).

## Comment Utiliser

1.  **Ouvrir `index.html`** dans votre navigateur.
2.  **Ajouter un Nœud** :
    *   Cliquez sur "Ajouter un Nœud".
    *   Remplissez les champs essentiels : `nodename` (le nom unique dans Rundeck) et `hostname` (l'adresse de connexion).
    .
3.  **Enrichir les Données** :
    *   Ajoutez des `tags` (ex: `web, prod, ubuntu`) pour faciliter le filtrage.
    *   Renseignez les attributs du système d'exploitation (`osFamily`, `osName`, etc.).
    *   Utilisez les **Attributs Personnalisés** pour stocker des métadonnées utiles. Par exemple :
        - `app_port: 8080`
        - `db_endpoint: db.example.com`
        - `backup_path: /mnt/backups`
4.  **Importer (Optionnel)** :
    *   Collez le contenu d'un fichier de ressources existant dans la zone d'import et cliquez sur "Importer" pour le modifier via l'interface.
5.  **Récupérer le YAML** :
    *   Le code YAML généré est disponible dans le panneau de droite.
    *   Copiez-le et enregistrez-le dans le fichier de ressources de votre projet Rundeck (ex: `/var/rundeck/projects/MyProject/etc/resources.yml`).

## Exemple de YAML Généré

Voici un exemple de ce que l'outil peut produire. Notez comment les attributs personnalisés (`app-port`, `api-key-path`) enrichissent la définition du nœud `api-server-01`.

```yaml
web-server-01:
  nodename: web-server-01
  hostname: 192.168.1.100
  username: rundeck
  description: Serveur web principal (Apache)
  tags: 'web, apache, prod'
  osFamily: unix
  osName: Linux
  osArch: x86_64
  ssh-key-storage-path: keys/prod/ssh-key.pem

api-server-01:
  nodename: api-server-01
  hostname: 192.168.1.101
  username: rundeck
  description: Serveur applicatif pour l'API
  tags: 'api, java, prod'
  osFamily: unix
  osName: Linux
  osArch: x86_64
  app-port: 9000
  api-key-path: 'keys/prod/api-key'
```

Ces attributs peuvent ensuite être utilisés dans vos jobs Rundeck via la syntaxe `@node.app-port@` ou `@node.api-key-path@`.