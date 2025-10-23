# Install Enterprise version of Rundeck in Cluster Mode

Premièrement, il est important de noter que **Rundeck Enterprise** est maintenant commercialisé sous le nom de **PagerDuty Process Automation (On Premise)**. Les documents que vous avez fournis, en particulier le guide de déploiement, confirment cela. L'installation "Entreprise" est conçue pour fonctionner en cluster afin d'assurer la haute disponibilité (HA) et la répartition de charge.

Voici les étapes clés pour réussir cette installation, basées sur les documents que vous m'avez donnés.

-----

## 1\. Prérequis Système

Avant de commencer, vous devez vous assurer que votre environnement respecte certains prérequis essentiels pour un déploiement en cluster :

  * **Système d'exploitation** : Serveurs Linux (les plus courants) ou Windows.
  * **Java** : Une version supportée de Java 8 est nécessaire.
  * **Base de données externe** : Oubliez la base de données H2 embarquée. Pour un cluster, une base de données externe (comme MySQL, PostgreSQL, Oracle, ou MS SQL Server) est **obligatoire**. Tous les membres du cluster doivent pointer vers cette même base de données partagée.
  * **Stockage de logs partagé** : Les logs d'exécution des jobs doivent être stockés dans un emplacement partagé accessible par tous les membres du cluster (par exemple, un montage NFS ou un bucket S3).
  * **Load Balancer (Répartiteur de charge)** : Un répartiteur de charge (comme HAProxy, Nginx, ou un service cloud type ELB) est nécessaire pour distribuer le trafic utilisateur entre les différents serveurs (nœuds) de votre cluster Rundeck.

-----

## 2\. Installation du logiciel "Rundeck Enterprise"

Vous pouvez installer le logiciel PagerDuty Process Automation (Rundeck Enterprise) de plusieurs manières. Les méthodes les plus courantes pour Linux sont via les gestionnaires de paquets `yum` (pour RHEL/CentOS) ou `apt` (pour Debian/Ubuntu).

Voici les ébauches de commandes typiques, basées sur la documentation fournie.

### Exemple : Installation avec `apt` (Debian/Ubuntu)

1.  **Ajouter le dépôt Enterprise :**

    ```bash
    # (La clé et l'URL exactes sont fournies par PagerDuty/Rundeck lors de l'achat)
    echo "deb https://rundeckpro.bintray.com/deb stable main" | sudo tee /etc/apt/sources.list.d/rundeck.list
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 379CE192D401AB61
    ```

2.  **Installer le paquet (notez le nom `rundeckpro-cluster`) :**

    ```bash
    sudo apt-get update
    sudo apt-get install rundeckpro-cluster 
    ```

    **

### Exemple : Installation avec `yum` (RHEL/CentOS)

1.  **Ajouter le dépôt Enterprise :**

    ```bash
    # (L'URL exacte est fournie par PagerDuty/Rundeck lors de l'achat)
    curl https://bintray.com/rundeckpro/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-rundeckpro-rpm.repo
    ```

2.  **Installer le paquet (notez le nom `rundeckpro-cluster`) :**

    ```bash
    sudo yum install java rundeckpro-cluster
    ```

    **

### Alternative : Installation "Launcher" (WAR)

Vous pouvez aussi utiliser le fichier `.war` exécutable (anciennement "launcher"). L'installation est similaire à la version open-source (définir `RDECK_BASE`, etc.), mais vous utiliserez le fichier `.war` fourni pour la version entreprise.

-----

## 3\. Installation de la Licence

La version entreprise ne fonctionnera pas sans une licence valide. Vous devez récupérer votre fichier `rundeckpro-license.key` (fourni par PagerDuty) et l'installer.

Vous pouvez le faire de deux manières:

1.  **Via l'interface graphique (GUI)** :

      * Connectez-vous à Rundeck.
      * Allez dans le menu Système (icône engrenage) \> "Licensing".
      * Cliquez sur "Upload License File" et sélectionnez votre fichier `rundeckpro-license.key`.

2.  **Via le système de fichiers** :

      * Copiez simplement le fichier de licence dans le répertoire de configuration de Rundeck. L'emplacement dépend de votre type d'installation :
          * **RPM/DEB** : `/etc/rundeck/rundeckpro-license.key` 
          * **Launcher** : `$RDECK_BASE/etc/rundeckpro-license.key` 

-----

## 4\. Configuration principale du Cluster

C'est l'étape la plus critique. Tous les nœuds de votre cluster doivent partager la même configuration. La configuration se fait principalement dans le fichier `rundeck-config.properties`.

  * **Pour une installation RPM/DEB** : `/etc/rundeck/rundeck-config.properties`
  * **Pour une installation Launcher** : `$RDECK_BASE/server/config/rundeck-config.properties`

Voici les modifications essentielles :

### A. Configurer la base de données partagée

Vous devez remplacer la configuration H2 par défaut par celle de votre base de données externe (MySQL, Postgres, etc.).

**Exemple (pour MySQL) :**

```properties
# Configuration de la base de données
dataSource.dbCreate = update
dataSource.driverClassName = com.mysql.jdbc.Driver
dataSource.url = jdbc:mysql://VOTRE_HOST_DB/rundeck?autoReconnect=true&useSSL=false
dataSource.username = rundeckuser
dataSource.password = rundeckpassword
```

**

### B. Activer le mode Cluster

Vous devez activer le mode cluster pour que les nœuds communiquent entre eux (heartbeat) et gèrent la reprise automatique (autotakeover) des tâches planifiées si un nœud tombe.

**Exemple de configuration de cluster :**

```properties
# Activer le mode cluster
rundeck.clusterMode.enabled = true

# Configuration du Heartbeat (exemple)
rundeck.clusterMode.heartbeat.interval = 30
rundeck.clusterMode.heartbeat.delay = 10
rundeck.clusterMode.heartbeat.considerInactive = 150
rundeck.clusterMode.heartbeat.considerDead = 300

# Activer la reprise automatique (Autotakeover)
rundeck.clusterMode.autotakeover.enabled = true
rundeck.clusterMode.autotakeover.policy = any
```

**

### C. Définir l'URL du Load Balancer

Rundeck doit connaître sa propre URL "publique", qui est celle de votre répartiteur de charge.

```properties
# URL publique de votre instance (celle du Load Balancer)
grails.serverURL = http://mon-load-balancer.mon-domaine.com
```

**

### D. Configurer le stockage des logs partagé

Vous devez également configurer le stockage partagé pour les logs d'exécution. Si vous utilisez S3, par exemple, vous activerez le plugin S3.

**Exemple (pour S3) :**

```properties
# Utiliser le plugin S3 pour le stockage des logs
# (Assurez-vous d'utiliser le plugin "pro" pour la visualisation en direct)
rundeck.execution.logs.fileStoragePlugin = com.rundeck.rundeckpro.amazon-s3

# Configuration du plugin S3 (dans framework.properties ou project.properties)
framework.plugin.ExecutionFileStorage.com.rundeck.rundeckpro.amazon-s3.bucket = nom-de-votre-bucket
framework.plugin.ExecutionFileStorage.com.rundeck.rundeckpro.amazon-s3.path = rundeck/logs/${job.project}/${job.execid}.log
# ... (plus d'options pour l'authentification AWS, la région, etc.)
```

**

-----

## Résumé

Pour installer la version entreprise, vous devez :

1.  Préparer une base de données externe et un stockage de logs partagé.
2.  Installer le paquet `rundeckpro-cluster` (ou le WAR entreprise).
3.  Placer votre fichier de licence `rundeckpro-license.key`.
4.  Configurer `rundeck-config.properties` pour pointer vers la base de données, activer le mode cluster et définir l'URL du répartiteur de charge.
