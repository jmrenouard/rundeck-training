# Guide Vulgarisé : Comprendre l'Autotakeover dans Rundeck

-----

## 1\. Le Concept : Qu'est-ce que l'Autotakeover ?

### L'explication théorique

Imaginez que vous avez configuré Rundeck en "cluster", c'est-à-dire avec plusieurs serveurs (nœuds) Rundeck qui travaillent ensemble pour des raisons de performance et de résilience.

**Le problème :** Vos jobs planifiés (par exemple, "faire une sauvegarde tous les soirs à 1h du matin") sont "possédés" par un membre spécifique du cluster. Mais que se passe-t-il si ce serveur tombe en panne (crash, maintenance, problème réseau) juste avant 1h du matin ?
**La réponse (sans Autotakeover) :** Le job ne s'exécute pas. Personne ne prend le relais. C'est un échec.

**La solution (avec Autotakeover) :** L'Autotakeover (ou "reprise automatique") est le mécanisme qui permet aux autres membres sains du cluster de détecter qu'un de leurs collègues est "mort" et de **prendre automatiquement la responsabilité** de ses jobs planifiés.

C'est comme une course de relais : si un coureur tombe, un autre membre de l'équipe ramasse le témoin (les jobs) et continue la course.

Pour que cela fonctionne, deux choses sont cruciales (et mentionnées dans votre document) :

1.  **Une base de données externe :** Tous les membres du cluster doivent partager la même base de données pour savoir quels jobs existent, qui doit les exécuter, etc.
2.  **Un répartiteur de charge (Load Balancer) :** Pour que vous (l'utilisateur) puissiez accéder à Rundeck via une seule URL, sans vous soucier de quel serveur est actif.

-----

## 2\. Le "Heartbeat" : Comment savoir qu'un nœud est "mort" ?

### L'explication théorique

Avant de prendre le contrôle des jobs de quelqu'un, il faut être sûr qu'il est vraiment hors-jeu. C'est le rôle du **"Heartbeat"** (battement de cœur).

Chaque membre du cluster envoie régulièrement un "battement de cœur" (un petit message réseau) pour dire "Je suis toujours en vie \!". Les autres membres écoutent ces battements.

Si un membre arrête d'envoyer son battement de cœur pendant un certain temps :

  * Il est d'abord considéré comme **"inactif"** (`considerInactive`).
  * Si cela dure encore plus longtemps, il est considéré comme **"mort"** (`considerDead`).

Ce n'est que lorsqu'un nœud est déclaré "mort" que l'Autotakeover se déclenche.

### L'exemple de configuration

Comme le montre votre document, cela se configure dans le fichier `rundeck-config.properties`. Voici une ébauche commentée :

```properties
# --- Configuration du Heartbeat ---

# Le nœud envoie un "je suis en vie" toutes les 30 secondes
rundeck.clusterMode.heartbeat.interval=30

# Il attend 10 secondes après son démarrage avant de commencer
rundeck.clusterMode.heartbeat.delay=10

# Si un nœud n'a pas donné de signe de vie depuis 150s (5x l'intervalle),
# on le considère "inactif" (peut-être un lag réseau temporaire)
rundeck.clusterMode.heartbeat.considerInactive=150

# Si un nœud n'a pas donné de signe de vie depuis 300s (10x l'intervalle),
# on le déclare officiellement "mort". L'Autotakeover peut commencer.
rundeck.clusterMode.heartbeat.considerDead=300
```

-----

## 3\. L'Autotakeover : La reprise des Jobs *Planifiés*

### L'explication théorique

Une fois qu'un nœud est "mort", le processus d'Autotakeover démarre. Un (ou plusieurs) des nœuds survivants va "proposer" de reprendre les jobs planifiés du nœud mort.

Les réglages contrôlent ce comportement :

  * `enabled=true` : Active la fonction (logique \!).
  * `policy` : C'est la règle : "Qui a le droit de reprendre les jobs ?". Nous y revenons à l'étape 5.
  * `delay` : Un temps d'attente avant de finaliser la reprise (une sécurité).
  * `sleep` : Un temps de pause entre les tentatives de reprise, pour éviter de surcharger le cluster.

### L'exemple de configuration

Voici la configuration de base pour activer la reprise automatique des *jobs planifiés* :

```properties
# --- Configuration de l'Autotakeover (pour les jobs planifiés) ---

# Oui, j'active la reprise automatique
rundeck.clusterMode.autotakeover.enabled=true

# "Any" = N'importe quel membre sain du cluster peut reprendre les jobs.
rundeck.clusterMode.autotakeover.policy=Any

# On attend 60 secondes après avoir détecté la mort avant de prendre les jobs
rundeck.clusterMode.autotakeover.delay = 60

# Si une tentative échoue, on attend 300s avant de réessayer
rundeck.clusterMode.autotakeover.sleep = 300
```

-----

## 4\. Recover Executions : La reprise des Jobs *en cours d'exécution*

### L'explication théorique

C'est un cas différent et très important. Que se passe-t-il si un nœud tombe en panne **pendant** qu'un job est en train de tourner ? (Ex: le job de sauvegarde de 1h du matin avait commencé à 1h00 et le serveur plante à 1h05).

Le job est maintenant "orphelin" et marqué comme "incomplet" ou "échoué".

La fonction **"Recover Executions"** permet à un autre nœud de reprendre ce job.
**Attention :** Cela ne reprend pas le job *exactement* là où il s'est arrêté. Cela fonctionne pour les jobs qui ont une option de **"Retry" (Réessayer)**. Le nœud survivant va simplement *relancer* le job depuis le début (ou l'étape échouée, si le workflow est bien conçu).

### L'exemple de configuration

Voici la configuration pour activer la reprise des *jobs en cours* (qui ont échoué à cause d'un crash) :

```properties
# --- Configuration de la Reprise d'Exécution (pour les jobs en cours) ---

# Oui, j'active la récupération des jobs qui tournaient sur un nœud mort
rundeck.clusterMode.recoverExecutions.enabled=true

# "Any" = N'importe quel membre sain peut tenter de relancer le job
rundeck.clusterMode.recoverExecutions.policy=Any

# On attend 30s avant de tenter de relancer le job échoué
rundeck.clusterMode.recoverExecutions.delay=30

# On attend 60s entre deux tentatives pour le même job
rundeck.clusterMode.recoverExecutions.sleep=60
```

-----

## 5\. Les Politiques (Policies) : Qui prend le relais ?

### L'explication théorique

Votre document mentionne trois politiques (`rundeck.clusterMode.autotakeover.policy`). C'est la stratégie de reprise :

1.  **`Any` (N'importe qui)** :

      * C'est la plus simple. Le premier nœud sain et disponible qui voit qu'un collègue est mort prend le relais.
      * *Idéal pour :* La plupart des clusters où tous les nœuds sont identiques.

2.  **`Static` (Statique)** :

      * C'est une politique restrictive. Vous définissez une liste (par UUID, l'identifiant unique d'un serveur) des nœuds qui sont *autorisés* à prendre le relais.
      * *Idéal pour :* Des architectures "Actif/Passif" où vous avez un serveur principal (Actif) et un serveur de secours dédié (Passif) qui ne doit rien faire d'autre que d'attendre une panne.

3.  **`RemoteExecution` (Exécution à distance)** :

      * C'est un cas plus avancé. Si vous utilisez les "Enterprise Runners" (des agents Rundeck distants), cette politique s'assure que la reprise respecte les règles de ces Runners. (Ne nous attardons pas trop dessus pour l'instant).

### L'exemple de configuration (pour `Static`)

Si vous vouliez une politique `Static` où seul le serveur avec l'UUID `uuid-serveur-secours-01` peut reprendre les jobs :

```properties
# On choisit la politique "Static"
rundeck.clusterMode.autotakeover.policy=Static

# On définit la liste des serveurs autorisés (ici, un seul)
rundeck.clusterMode.autotakeover.config.allowed=uuid-serveur-secours-01
```

-----

## Résumé

Pour résumer, l'**Autotakeover** est un ensemble de fonctionnalités vitales pour un cluster Rundeck :

1.  Le **Heartbeat** surveille qui est en vie.
2.  L'**Autotakeover** (standard) s'assure que les *futurs jobs planifiés* d'un nœud mort sont repris par un autre.
3.  Le **Recover Executions** s'assure que les *jobs qui étaient en cours* sur le nœud mort sont relancés (s'ils sont configurés pour).

C'est un concept clé pour rendre votre automatisation robuste et fiable \!
