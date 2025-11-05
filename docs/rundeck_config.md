# rundeck-config.properties
-----

## Configuration `rundeck-config.properties` (Analyse OSS vs Enterprise)

Le fichier `rundeck-config.properties` (ou `rundeck.properties` pour les installations RPM/DEB) est le point de configuration central de l'instance Rundeck/PagerDuty Process Automation. Il gère les connexions (web, DB), la sécurité, l'exécution et les fonctionnalités avancées.

### 🌐 Configuration Serveur et Réseau (Base OSS)

Ces paramètres définissent comment le serveur Rundeck est exposé et comment il écoute.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `grails.serverURL` | URL d'accès web publique complète à Rundeck. | `http://localhost:4440` | **Crucial**. Doit être l'URL finale vue par l'utilisateur (après proxy/LB). (OSS) |
| `server.port` | Port HTTP d’écoute du service Java. | `4440` | (OSS) |
| `server.address` | IP/Hôte d’écoute. | `localhost` | Changer pour `0.0.0.0` pour écouter sur toutes les interfaces réseau. (OSS) |
| `server.servlet.context-path` | Préfixe d’URI applicatif. | `/` | Mettre `/rundeck` si servi via un proxy sur un sous-chemin. (OSS) |
| `rundeck.web.proxy.enabled` | Indique si Rundeck est derrière un proxy. | `false` | (OSS) |
| `server.https.port` | Port HTTPS d’écoute (si SSL natif activé). | `4443` | (OSS) |
| `rundeck.web.ssl.enabled` | Active le SSL natif (Jetty). | `false` | (OSS) Recommandé : gérer le SSL au niveau d'un Load Balancer/Proxy (NGINX, HAProxy). |
| `rundeck.web.ssl.keystore` | Chemin keystore SSL (JKS). | (vide) | (OSS) |
| `rundeck.web.ssl.keystorePassword` | Mot de passe keystore. | (vide) | (OSS) |

-----

### 🗃️ Base de Données (Base OSS)

Définit la connexion à la base de données relationnelle (H2, MySQL, Postgres, MSSQL).

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `dataSource.url` | URL JDBC de la base de données. | `jdbc:h2:file:/...` | **Critique en production**. H2 (par défaut) n'est *pas* supporté pour la production ou le clustering. (OSS) |
| `dataSource.username` | Utilisateur de la base de données. | `rundeck` | (OSS) |
| `dataSource.password` | Mot de passe de la base de données. | `rundeck` | (OSS) Ce mot de passe peut être chiffré (voir section sécurité). |
| `dataSource.driverClassName` | Classe du driver JDBC. | `org.h2.Driver` | Ex: `com.mysql.cj.jdbc.Driver` (MySQL 8+), `org.postgresql.Driver` (Postgres). (OSS) |

-----

### 🏃‍♂️ Exécution, Jobs et SSH (Base OSS)

Contrôle le comportement de l'exécution des jobs et les paramètres SSH par défaut.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `rundeck.executionMode` | Mode d’exécution global. | `active` | Mettre `passive` pour désactiver l'exécution des jobs (mode maintenance). (OSS) |
| `rundeck.ssh.keypath` | Chemin clé privée SSH *par défaut* pour le nœud. | `~/.ssh/id_rsa` | (OSS) Obsolète. Préférer le stockage de clés (Key Storage) pour la sécurité. |
| `rundeck.ssh.user` | Utilisateur SSH *par défaut*. | (vide) | (OSS) Préférer la définition au niveau du nœud ou du job. |
| `rundeck.ssh.timeout` | Timeout SSH (en millisecondes). | `0` | `0` = infini. (OSS) |
| `rundeck.jobs.retry.max` | Nombre maximum de tentatives sur un job (si échec). | `0` | (OSS) |
| `rundeck.jobs.default.timeout` | Timeout par défaut pour les jobs (format `1m`, `2h30m`). | `0` | `0` = aucun timeout. (OSS) |

-----

### 🔐 Sécurité et Authentification (Mixte OSS/Enterprise)

Cette section est fondamentale et présente les plus grandes différences entre OSS et Enterprise.

#### Sécurité de Base (OSS)

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `rundeck.security.useHMacRequestTokens` | Utilise des tokens HMAC pour l'API (recommandé). | `true` | (OSS) |
| `rundeck.api.tokens.duration.max` | Durée max des tokens API (ex: `30d`, `1y`). `0` = illimité. | `30d` | (OSS) |
| `rundeck.web.session.timeout` | Timeout session Web (en secondes). | `1800` | (OSS) 30 minutes. |
| `rundeck.password.reset.enabled` | Autorise la réinitialisation du mot de passe `admin` au démarrage. | `true` | (OSS) **Doit être mis à `false`** après la configuration initiale. |
| `rundeck.security.authorization.preauthenticated.enabled` | Active l'authentification pré-authentifiée (ex: via proxy). | `false` | (OSS) |

#### Sécurité Avancée (Enterprise)

Ces fonctionnalités nécessitent une licence PagerDuty Process Automation.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (Enterprise) |
| :--- | :--- | :--- | :--- |
| `rundeck.enterprise.license.file` | Chemin vers le fichier de licence. | (vide) | **Requis** pour activer *toutes* les fonctionnalités Enterprise. |
| `rundeck.encryption.enabled` | Active le chiffrement des propriétés de configuration (ex: `dataSource.password`). | `false` | (Enterprise) Nécessite un "Encryption Plugin" (ex: JCEKS, HashiCorp Vault). |
| `rundeck.security.realms.file` | Chemin vers `realm.properties` (gestion auth). | `.../realm.properties` | (OSS) |
| `rundeck.security.auth.modules.conf` | Chemin vers le fichier de configuration JAAS (ex: `jaas-activedirectory.conf`). | (vide) | (OSS/Enterprise) Les modules LDAP/AD sont OSS, mais SAML/OIDC sont Enterprise. |
| `rundeck.security.sso.login.enabled` | Active l'authentification SSO (SAML, OIDC). | `false` | (Enterprise) |
| `rundeck.security.sso.serviceName` | Nom du service affiché sur la page de login SSO. | `Rundeck` | (Enterprise) |

-----

### 🚀 Fonctionnalités Enterprise (Clustering, Runners, Stockage)

Ces paramètres n'existent ou ne sont fonctionnels que dans la version Enterprise.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (Enterprise) |
| :--- | :--- | :--- | :--- |
| `rundeck.clusterMode.enabled` | **Active le mode Cluster (HA).** | `false` | (Enterprise) Nécessite une base de données externe (MySQL/Postgres) et un stockage partagé. |
| `rundeck.clusterMode.serverUUID` | UUID unique de ce membre du cluster. | (généré) | (Enterprise) Doit être défini manuellement et être unique pour chaque nœud du cluster. |
| `rundeck.server.uuid` | UUID unique du serveur (utilisé même hors cluster). | (généré) | (OSS/Enterprise) |
| `rundeck.execution.logs.storage.type` | Type de stockage pour les logs d'exécution. | `file` | (Enterprise) Mettre `s3` ou `azure-blob` pour le stockage cloud. |
| `rundeck.execution.logs.storage.s3.bucket` | Bucket S3 pour le stockage des logs. | (vide) | (Enterprise) |
| `rundeck.storage.provider.1.type` | Type de stockage pour le "Key Storage". | `file` | (Enterprise) Mettre `vault-kv` pour utiliser HashiCorp Vault. |
| `rundeck.storage.provider.1.path` | Chemin de base dans le "Key Storage" (ex: `keys`). | `keys` | (Enterprise) |

> **Note sur les Enterprise Runners :** La configuration des Runners (automates d'exécution distants) se fait principalement via l'interface graphique (GUI) de PagerDuty Process Automation (voir le document `pa-deployment-guide.pdf`, p. 17-18) et non via `rundeck-config.properties`. Les Runners sont ensuite ciblés par des tags au niveau des jobs.

-----

### 📈 Audit et Logs (Base OSS)

Gestion des logs applicatifs et de l'audit des actions.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `loglevel.default` | Niveau de log global (ex: `INFO`, `DEBUG`, `WARN`). | `INFO` | (OSS) Mettre `DEBUG` pour le troubleshooting. |
| `framework.logs.dir` | Dossier des logs applicatifs. | `$RDECK_BASE/var/logs` | (OSS) |
| `rundeck.audit.actions.enabled` | Active l'audit des actions utilisateur (création/modif/suppr). | `true` | (OSS) |
| `rundeck.audit.storage.type` | Type de stockage pour les logs d'audit. | `filesystem` | (OSS) |
| `rundeck.audit.storage.dir` | Dossier des logs d'audit (si type=filesystem). | `$RDECK_BASE/var/audit` | (OSS) |

-----

### 🎨 Interface (GUI) et Projets (Base OSS)

Personnalisation de l'interface utilisateur et gestion des projets.

| Paramètre | Définition / Usage | Valeur par défaut | Notes (OSS / Enterprise) |
| :--- | :--- | :--- | :--- |
| `rundeck.gui.title` | Titre personnalisé de l'UI (Branding). | `Rundeck` | (OSS) |
| `rundeck.gui.instanceName` | Nom d’instance (affiché dans l'UI). | (vide) | (OSS) Utile pour distinguer Prod/Dev/QA. |
| `rundeck.gui.logo` | Chemin logo personnalisé (ex: `/assets/my-logo.png`). | (vide) | (OSS) |
| `rundeck.project.directory` | Dossier racine contenant les projets. | `$RDECK_BASE/projects` | (OSS) |
| `rundeck.feature.option-values-plugin.enabled` | Active les plugins d'options dynamiques. | `true` | (OSS) |

-----

### ⚠️ Risques de Sécurité et Bonnes Pratiques

L'exploitation de `rundeck-config.properties` requiert une attention particulière :

1.  **Exposition des Secrets :**

      * **Risque :** Le paramètre `dataSource.password` (et les identifiants SMTP) sont stockés en clair par défaut dans ce fichier (OSS).
      * **Solution (OSS) :** Restreindre les permissions (lecture/écriture) de ce fichier au seul utilisateur exécutant le service Rundeck (ex: `chmod 600`).
      * **Solution (Enterprise) :** Utiliser `rundeck.encryption.enabled=true` et un plugin de chiffrement (Vault, JCEKS) pour chiffrer ces valeurs.

2.  **Accès Réseau :**

      * **Risque :** Configurer `server.address=0.0.0.0` expose l'instance Rundeck sur toutes les interfaces réseau.
      * **Solution :** Il est impératif de placer l'instance derrière un reverse proxy (NGINX, HAProxy) ou un Load Balancer qui gère le SSL/TLS et filtre l'accès. Ne jamais exposer le port 4440/4443 directement sur Internet.

3.  **Configuration Initiale :**

      * **Risque :** Laisser `rundeck.password.reset.enabled=true` permet à quiconque ayant accès à la machine (et pouvant redémarrer le service) de réinitialiser le mot de passe `admin`.
      * **Solution :** Mettre ce paramètre à `false` immédiatement après la première connexion et la configuration d'un compte administrateur sécurisé.

-----

### 📚 Sources

  * **PagerDuty (Auteur)** (2024). *Rundeck Configuration - rundeck-config.properties*. [https://docs.rundeck.com/docs/administration/configuration/rundeck-config.html](https://www.google.com/search?q=https://docs.rundeck.com/docs/administration/configuration/rundeck-config.html) (Documentation officielle principale pour les paramètres).
  * **PagerDuty (Auteur)** (2024). *Cluster Administration*. [https://docs.rundeck.com/docs/administration/cluster/](https://docs.rundeck.com/docs/administration/cluster/) (Référence pour les paramètres `rundeck.clusterMode.*` Enterprise).
  * **PagerDuty (Auteur)** (2024). *Security - Storage Encryption*. [https://docs.rundeck.com/docs/administration/security/storage-encryption.html](https://www.google.com/search?q=https://docs.rundeck.com/docs/administration/security/storage-encryption.html) (Référence pour `rundeck.encryption.enabled` Enterprise).
  * **PagerDuty (Auteur)** (2024). *Enterprise Runner Overview*. [https://docs.rundeck.com/docs/enterprise/runner/](https://www.google.com/search?q=https://docs.rundeck.com/docs/enterprise/runner/) (Référence confirmant la configuration des Runners via GUI/API plutôt que `rundeck-config.properties`).
