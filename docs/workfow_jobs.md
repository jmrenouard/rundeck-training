# Comprendre les workflows dans RundeckCe rapport explore de manière pédagogique et exhaustive le fonctionnement, la configuration et la puissance des workflows dans Rundeck, en mettant un accent sur les stratégies d’exécution et la gestion avancée via le Ruleset Workflow Strategy.

## Résumé des points clésLes workflows sont le cœur de l’automatisation avec Rundeck. Ils structurent des suites d’actions (étapes) orchestrées selon des stratégies précises, offrant robustesse, flexibilité et visibilité. Plusieurs modes d’exécution sont disponibles : séquentiel, node-first, parallèle et, pour les besoins complexes, le Ruleset. Chacune de ces stratégies répond à des besoins spécifiques en termes d’orchestration, gestion d’erreur, et conditionnalité. La compréhension de ces stratégies permet d’automatiser des processus IT de manière fiable et contrôlée.

## Structure et composantes d’un workflow RundeckUn **workflow** dans Rundeck représente une séquence d’étapes qui s’exécutent afin d’accomplir une tâche automatisée. Voici les principaux éléments structurants :

- **Étapes du workflow** : chaque étape définit une action, un script, une commande, un appel de job ou un plugin.
- **Stratégie d’exécution** : détermine l’ordre et la logique d’exécution des étapes.
- **Gestion des erreurs** (Error Handlers) : permet de réagir à un échec dans le workflow (rollback, log, etc.).
- **Variables de contexte** : facilitent le passage d’informations entre étapes, avec différents scopes (job, nœud, option).

Composants principaux d'un workflow Rundeck :### Création d’un workflowLa création s’effectue via la console Rundeck (GUI) ou est décrite dans un fichier YAML/XML. Les étapes sont ajoutées, ordonnées et configurées avec éventuellement des gestionnaires d’erreurs. Il est possible d’exporter/importer les définitions de jobs pour versionner son automation.

## Stratégies de workflow : orchestrer l’exécutionRundeck offre plusieurs stratégies pour piloter l’enchaînement des étapes :

### 1. **Node First (par défaut et le plus courant)**- Exécute la séquence d’étapes complète sur un nœud, puis passe au nœud suivant.
- Privilégie la logique "par nœud" : chaque système cible subit tout le workflow avant de passer au suivant.

### 2. **Sequential (séquentiel)**- Exécute chaque étape sur tous les nœuds avant de passer à l’étape suivante.
- Favorise la logique "par étape" : une action est propagée sur tous les nœuds, puis la suivante.

### 3. **Parallel (parallèle)**- Toutes les étapes sont exécutées simultanément sur tous les nœuds (dans la limite des ressources/disponibilités).

### Illustration des stratégies d’exécutionComparaison des stratégies de workflow dans Rundeck :- **Node First** : NodeA effectue steps 1 à 3, ensuite c’est au tour de NodeB.
- **Sequential** : Step 1 est jouée sur NodeA puis NodeB, ensuite step 2, etc.
- **Parallel** : Les étapes sont lancées en même temps sur tous les nœuds si possible.

### Choix de la stratégieLa stratégie dépend de la logique métier : traitement localisé sur chaque nœud (Node First), exécution groupée par action (Sequential), ou optimisation des temps d’exécution (Parallel). Les workflows plus complexes tirent avantage de la stratégie Ruleset.

## Gestion des erreurs et tolérance aux incidentsChaque étape du workflow peut se voir adjoindre un **Error Handler** : une action exécutée en cas d’échec, permettant de traiter l’erreur (notification, rollback, collecte de logs).  
Le comportement global à l’échec est paramétrable :

- **Arrêt immédiat** : stoppe le workflow à la première erreur (par défaut)
- **Continuer malgré l’échec** : exécute les étapes restantes avant d’échouer formellement le job

La combinaison des gestionnaires d’erreur et de ces options permet de bâtir des workflows très robustes.

## Le Ruleset Workflow Strategy : orchestration avancée (Enterprise)La stratégie **Ruleset** (Rundeck Enterprise) va beaucoup plus loin en proposant une orchestration conditionnelle et événementielle puissante.

### Principes- Définition de règles (rules) pour chaque étape ou groupe d’étapes.
- Directives (run-at-start, run-in-sequence, run-after:X) pour orchestrer l’ordre.
- Conditions (`if:expression`, `unless:expression`) pour contrôler l’exécution selon les variables de contexte ou options du job.

### Syntaxe de base```txt
[Step] [directive] [condition]
```
- `[1] run-at-start` : step 1 démarre immédiatement
- `[3] run-after:1 if:option.env==PROD` : step 2 après 1, si l’option env vaut PROD

### Exemples de règles avancées- Lance steps 2 et 5 seulement après la fin de 1 :
  ```
  [2,5] run-after:1
  ```
- Orchestre en parallèle steps 2 et 3, puis step 4 :
  ```
  [3] run-after:1
  [3] run-after:1
  [4] run-after:2,3
  ```
- Conditions multiples (AND sur une ligne, OR sur plusieurs) :
  ```
  [3,4,5] if:option.1>0
  [3,4,5] if:option.2==true  # résulte en un OR
  [2] if:option.1==yes if:option.2==yes  # résulte en un AND
  ```

- Cas d’usage : décision dynamique du chemin d’exécution selon l’environnement, des paramètres utilisateurs ou des résultats d’étape.

### Limites- La stratégie Ruleset n’est accessible qu’aux versions Enterprise et requiert de la rigueur pour organiser de nombreux jobs (problèmes de lisibilité/performance de l’éditeur graphique avec de gros workflows).
- Les conditions n’ont pas accès aux variables contextuelles des nœuds individuels.

## Context Variables : le fil conducteur du workflowRundeck expose un large ensemble de variables, pour enrichir la logique de vos workflows :

- **Variables job** : nom, groupe, ID, projet, utilisateur, etc.
- **Variables node** : nom de nœud, hostname, utilisateur SSH, tags, etc.
- **Variables d’option** : saisies utilisateur à l’exécution
- **Variables d’exécution** : statut, date de début/fin, nœuds ayant échoué, etc.

Ces variables sont utilisables dans toutes les étapes et directives (ex : `option.env`, `job.name`, `node.hostname`). L’exposition de ces variables permet du templating, du routage conditionnel et du reporting détaillé en fin de job.

## Bonnes pratiques et conseils- **Toujours documenter** chaque étape et gestionnaire d’erreur
- **Préférer une organisation logique** : nommer les étapes clé, utiliser des descriptions explicites
- **Utiliser la stratégie adaptée** :
  - *Node First* pour des tâches unitaires ou non parallélisables
  - *Sequential* pour un déploiement progressif/ordonné
  - *Parallel* pour optimiser les délais sur des tâches indépendantes
- **Rendre explicites les attentes d’échec** avec les error handlers et la gestion du « keepgoing »
- **Exploiter le Ruleset** pour des workflows dynamiques et conditionnels dans des architectures avancées

## ConclusionLa maîtrise des stratégies de workflow et du Ruleset dans Rundeck permet d’automatiser des processus complexes en toute fiabilité. Grâce à sa modularité et à sa richesse fonctionnelle, Rundeck s’adapte à tous les niveaux de complexité, du runbook simple aux chaînes d’orchestration agiles pilotées par conditions. Pour aller plus loin, l’utilisation des variables contextuelles et des logs enrichis via les log filters parachève le pilotage et l’analyse de vos exécutions. Adoptez une démarche incrémentale, testez régulièrement vos workflows avec différents sets d’options, et profitez de la puissance d’automatisation qu’offre Rundeck !

[1](https://docs.rundeck.com/docs)
[2](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/29cde0b2-d80b-45a3-9404-036b7c1072de/all_docs_rundeck.pdf)
[3](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/9e8e75f2-c42b-427f-8532-4ea5b47d68cf/all_docs_rundeck.txt)