# Guide Vulgarisé : Comprendre l'Exécution à Distance dans un Cluster Rundeck

-----

## 1\. Qu'est-ce que l'Exécution à Distance en Cluster ?

Imaginez que votre installation Rundeck est un "cluster", c'est-à-dire un groupe de serveurs travaillant ensemble pour ne pas qu'un seul serveur fasse tout le travail.

Par défaut, quand vous lancez un job, le serveur Rundeck qui reçoit la demande (par exemple, celui sur lequel vous êtes connecté) l'exécute lui-même.

L'**Exécution à Distance** permet à ce serveur de dire : "Hé, je suis peut-être occupé, ou bien ce n'est pas mon rôle. Je vais plutôt **transférer ce job à un autre membre** du cluster pour qu'il s'en charge."

C'est la clé pour équilibrer la charge de travail sur l'ensemble de vos serveurs Rundeck.

**Où ça se configure ?**
Tout se passe principalement dans votre fichier de configuration central : `rundeck-config.properties`.

-----

## 2\. Le Cœur du Système : Les Stratégies (Policies)

La première chose à décider est : **comment** Rundeck va-t-il choisir le membre qui exécutera le job ? C'est ce qu'on appelle la "Policy" (stratégie).

Vous définissez votre stratégie globale avec cette ligne :
`rundeck.clusterMode.remoteExecution.policy = <Policy>`

Voici les choix possibles, du plus simple au plus intelligent :

  * **`None` (Défaut)**

      * **Ce que ça fait :** Aucune exécution à distance. Le membre qui reçoit le job l'exécute localement.
      * **Quand l'utiliser :** Si vous ne voulez pas de répartition de charge pour les jobs.

  * **`Random`**

      * **Ce que ça fait :** Choisit un membre *au hasard* parmi ceux autorisés (on verra "autorisés" juste après).
      * **Quand l'utiliser :** Pour une répartition simple et basique.

  * **`RoundRobin`**

      * **Ce que ça fait :** Distribue les jobs "chacun son tour", comme on distribue des cartes (Membre A, puis Membre B, puis Membre C, puis retour au Membre A...).
      * **Quand l'utiliser :** Pour une répartition équitable et prévisible.

  * **`Preset`**

      * **Ce que ça fait :** Exécute *toujours* sur un autre membre spécifique que vous avez prédéfini.
      * **Quand l'utiliser :** Si vous avez un membre "dédié" aux exécutions et que les autres ne servent qu'à planifier.

  * **`Load` (Commercial)**

      * **Ce que ça fait :** C'est la stratégie la plus "intelligente". Elle transfère le job au membre du cluster qui est le *moins* occupé (en se basant sur l'utilisation du CPU et des threads).
      * **Quand l'utiliser :** C'est la méthode recommandée pour une véritable répartition de charge dynamique.

-----

## 3\. Définir QUI peut exécuter les jobs

Maintenant que vous avez choisi une *stratégie* (ex: `RoundRobin`), il faut définir le "groupe" de membres parmi lesquels choisir.

### a) Membres Autorisés (`allowed`)

On utilise `rundeck.clusterMode.remoteExecution.config.allowed = <Liste>`

  * `Self` : Le membre local (lui-même).
  * `Other` : N'importe quel *autre* membre du cluster.
  * `UUID` : L'identifiant unique d'un membre spécifique.
  * `/regex/` : Une expression régulière pour cibler plusieurs UUID.

**Exemple concret :**
Je veux une répartition en "RoundRobin" (chacun son tour) mais *jamais* sur le membre local. Je veux que seuls les *autres* membres travaillent.

```properties
# Stratégie : chacun son tour
rundeck.clusterMode.remoteExecution.policy = RoundRobin
# Membres autorisés : Tous les autres, sauf moi
rundeck.clusterMode.remoteExecution.config.allowed = Other
```

### b) Filtrer avec des Tags (`allowedTags` / `preferredTags`)

C'est ici que ça devient très puissant. Vous pouvez "étiqueter" (tagger) vos membres de cluster (dans leur fichier `framework.properties`) avec des rôles. Par exemple : `rundeck.server.tags=worker,linux`

  * `allowedTags` : N'autorise l'exécution que sur les membres ayant ce tag.
  * `preferredTags` : *Préfère* les membres avec ce tag, mais si aucun n'est dispo, se rabat sur les autres membres autorisés (`allowed`).

**Exemple concret :**
Je veux une répartition `RoundRobin`. Je *préfère* que les jobs tournent sur mes membres tagués "worker" ou "secondary". Si aucun n'est disponible, je me rabats sur n'importe quel *autre* membre du cluster.

```properties
# Stratégie : chacun son tour
rundeck.clusterMode.remoteExecution.policy = RoundRobin
# Cible : N'importe qui d'autre que moi...
rundeck.clusterMode.remoteExecution.config.allowed = Other
# ...mais limite la sélection à TOUS les tags (ici, *)
rundeck.clusterMode.remoteExecution.config.allowedTags = *
# ...MAIS, en priorité, utilise ceux tagués "worker" ou "secondary"
rundeck.clusterMode.remoteExecution.config.preferredTags = worker,secondary
```

-----

## 4\. Aller plus loin : Les Profils par Projet

Et si vous ne voulez pas la *même* stratégie pour *tous* vos projets ?
Vous pouvez créer des **Profils**. Un profil lie une configuration spécifique (stratégie, membres autorisés...) à un ou plusieurs projets.

**Exemple concret :**
Je veux un profil "Linux" pour mes projets "ProjectA" et "ProjectB". Pour ces projets, je veux *forcer* l'exécution sur un membre bien précis (stratégie `Preset`) identifié par son UUID.

```properties
# 1. Je déclare l'existence d'un profil nommé "Linux"
rundeck.clusterMode.remoteExecution.profiles = Linux

# 2. J'assigne des projets à ce profil
rundeck.clusterMode.remoteExecution.profile.Linux.projects=projectA, projectB

# 3. Je définis la configuration POUR CE PROFIL
# Stratégie : Toujours le même membre
rundeck.clusterMode.remoteExecution.profile.Linux.policy=Preset
# Lequel ? Celui avec cet UUID spécifique
rundeck.clusterMode.remoteExecution.profile.Linux.config.uuid=<UUID-DU-MEMBRE-LINUX-DEDIE>
```

Pour tous les autres projets non listés (ex: "ProjectC"), Rundeck utilisera la politique *par défaut* définie à la racine (voir étape 2).

-----

## 5\. Sécurité et Pannes

Deux derniers points importants tirés de votre document :

  * **Sécurité (Secure Options) :** Si vos jobs utilisent des options sécurisées (des mots de passe, des clés privées...), Rundeck chiffre *automatiquement* la communication lorsqu'il transfère le job à un autre membre.

      * **Important :** Si vous désactivez ce chiffrement (`rundeck.clusterMode.messaging.encryption.enabled = false`), les jobs avec options sécurisées **refuseront** d'être exécutés à distance et tourneront localement. Ne désactivez pas cela sans une bonne raison.

  * **Pannes (Execution Cleaning) :**

      * **Stale (Obsolète) :** Si un membre lance un job et *tombe en panne* au milieu, l'exécution sera marquée comme "Incomplete" (Incomplète) une fois le cluster stabilisé.
      * **Missed (Manquée) :** Si un membre *devait* lancer un job (planifié) mais tombe en panne *avant*, le cluster le marquera comme "missed" (manqué) pour vous avertir.

-----

## Résumé

Pour mettre en place l'exécution à distance :

1.  **Commencez simple :** Ouvrez `rundeck-config.properties`.
2.  **Choisissez votre stratégie** de base (ex: `RoundRobin`) avec `rundeck.clusterMode.remoteExecution.policy`.
3.  **Définissez le "pool"** de membres (ex: `Other`) avec `rundeck.clusterMode.remoteExecution.config.allowed`.
4.  **Affinez (optionnel)** avec des `allowedTags` ou des `preferredTags` pour plus de contrôle.
5.  **Spécialisez (optionnel)** avec des `profiles` si différents projets ont des besoins différents.

Voilà \! Vous avez les concepts clés pour bâtir un cluster Rundeck robuste et performant. N'hésitez pas à tester d'abord avec `Random` ou `RoundRobin` pour voir vos exécutions se répartir sur les différents membres de votre cluster (visible dans l'interface de gestion du cluster).
