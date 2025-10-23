# Tuning et Optimisation de Rundeck

-----

## Guide du Tuning Rundeck

Optimiser Rundeck consiste principalement à ajuster la configuration pour qu'elle corresponde à la charge de travail spécifique de *votre* environnement. Cela implique souvent d'allouer plus de ressources (mémoire, descripteurs de fichiers) et d'ajuster les "pools" de workers (threads).

### 1\. Descripteurs de Fichiers (File Descriptors)

**🤔 Pourquoi c'est important ?**
Le processus serveur de Rundeck ouvre constamment des fichiers : bibliothèques Java, fichiers de log, et surtout des connexions réseau (sockets) pour les jobs, les requêtes API, et l'interface utilisateur. Chaque système d'exploitation impose une limite au nombre de fichiers qu'un seul processus peut ouvrir simultanément.

**🚨 Symptôme courant :**
Si vous atteignez cette limite, Rundeck plantera ou refusera de nouvelles connexions/jobs, et vous verrez une erreur fatidique dans `service.log` :
`Too many open files`

**🛠️ Comment l'ajuster (sur Linux) ?**

1.  **Vérifier la limite actuelle (pour l'utilisateur qui lance Rundeck) :**

    ```bash
    ulimit -n
    ```

    Une valeur basse comme `1024` est souvent insuffisante pour une instance Rundeck active.

2.  **Vérifier l'utilisation actuelle (optionnel mais utile) :**
    Trouvez le PID (Process ID) de votre processus Rundeck (par ex. avec `ps aux | grep rundeck`) puis lancez :

    ```bash
    # Remplacez <rundeck_pid> par l'ID du processus
    lsof -p <rundeck_pid> | wc -l
    ```

    Cela vous donne le nombre de fichiers actuellement ouverts par Rundeck.

3.  **Augmenter la limite de manière permanente :**
    Il est recommandé de définir une marge large. Éditez le fichier `/etc/security/limits.conf` pour augmenter les limites "soft" (applicables par défaut) et "hard" (le plafond maximum) pour l'utilisateur qui exécute Rundeck (par exemple, `rundeck`).

    ```text
    # Ajouter ces lignes à /etc/security/limits.conf
    # (Exemple avec l'utilisateur 'rundeck' et une limite de 65535)
    rundeck hard nofile 65535
    rundeck soft nofile 65535
    ```

4.  **Augmenter la limite au niveau du système (optionnel) :**
    Vous pouvez aussi vérifier la limite globale du système :

    ```bash
    cat /proc/sys/fs/file-max
    ```

    Et l'augmenter si nécessaire (par exemple, `echo 65535 > /proc/sys/fs/file-max`).

5.  **Appliquer & Redémarrer :**
    Vous devrez peut-être vous déconnecter/reconnecter pour que les limites de `limits.conf` s'appliquent. Assurez-vous aussi que la limite est bien appliquée au démarrage de Rundeck (parfois via `ulimit -n 65535` dans le script de démarrage ou le fichier `profile`).
    **Redémarrez ensuite le service Rundeck.**

-----

### 2\. Taille du Tas Java (Java Heap Size)

**🤔 Pourquoi c'est important ?**
Rundeck est une application Java. Elle a besoin de mémoire vive (RAM) pour fonctionner. La "Heap Size" (taille du tas) est la quantité maximale de RAM que la Machine Virtuelle Java (JVM) est autorisée à allouer à Rundeck.

**🚨 Symptôme courant :**
Si Rundeck manque de mémoire pour traiter les sessions utilisateur, les définitions de jobs, les logs en temps réel ou les données des nœuds, il plantera avec une erreur :
`Exception in thread "main" java.lang.OutOfMemoryError: Java heap space`

**🛠️ Comment l'ajuster ?**

La taille du tas est contrôlée par deux paramètres de la JVM :

  * `-Xms<taille>`: Taille **initiale** du tas (la mémoire allouée au démarrage).
  * `-Xmx<taille>`: Taille **maximale** du tas (la mémoire maximale que Rundeck peut utiliser).

Par défaut, l'installeur met souvent `-Xmx1024m` (1Go) et `-Xms256m` (256Mo).

**Où modifier ces valeurs ?**

  * **Installation "Launcher" (fichier .jar) :**
    Éditez le fichier `$RDECK_BASE/etc/profile`. Recherchez les lignes contenant `Xmx` et `Xms`.

  * **Installation RPM (CentOS/RHEL) :**
    Créez ou éditez le fichier `/etc/sysconfig/rundeckd` et ajoutez :

    ```bash
    # Exemple pour passer à 4Go max et 1Go initial
    RDECK_JVM_SETTINGS="$RDECK_JVM_SETTINGS -Xmx4096m -Xms1024m"
    ```

  * **Installation DEB (Debian/Ubuntu) :**
    Créez ou éditez le fichier `/etc/default/rundeckd` et ajoutez :

    ```bash
    # Exemple pour passer à 4Go max et 1Go initial
    RDECK_JVM_SETTINGS="$RDECK_JVM_SETTINGS -Xmx4096m -Xms1024m"
    ```

**Conseils de dimensionnement :**
La mémoire nécessaire dépend :

  * Du nombre de nœuds gérés (le modèle de ressource est chargé en mémoire).
  * Du nombre de jobs exécutés simultanément.
  * Du nombre d'utilisateurs actifs sur l'interface web.
  * De la taille des logs de jobs (surtout s'ils sont affichés dans l'interface).

Pour une instance gérant plus de 1000 nœuds avec des dizaines d'utilisateurs, 4Go ( `-Xmx4096m`) est un bon point de départ.

**N'oubliez pas de redémarrer Rundeck après modification.**

-----

### 3\. Nombre de Threads de Jobs (Quartz ThreadCount)

**🤔 Pourquoi c'est important ?**
Rundeck utilise un ordonnanceur (appelé "Quartz") pour gérer l'exécution des jobs (jobs planifiés, jobs lancés manuellement, commandes ad-hoc). Le `threadCount` définit le **nombre maximal de jobs pouvant s'exécuter en même temps**.

Par défaut, cette valeur est très basse : **10**.

**🚨 Symptôme courant :**
Vous avez 50 jobs qui doivent se lancer à 14h00. Vous remarquez que seuls 10 se lancent, et les 40 autres restent en file d'attente ("queued") et ne démarrent que lorsque les premiers se terminent.

**🛠️ Comment l'ajuster ?**

1.  Éditez votre fichier de configuration principal : `rundeck-config.properties` (souvent dans `/etc/rundeck/` ou `$RDECK_BASE/server/config/`).

2.  Ajoutez ou modifiez la ligne suivante :

    ```properties
    # Exemple pour autoriser 50 exécutions concurrentes
    quartz.threadPool.threadCount = 50
    ```

**Conseils de dimensionnement :**

  * **Relation Mémoire/Threads :** Plus vous augmentez le nombre de threads, plus vous augmentez la consommation de mémoire (chaque job en cours consomme de la RAM). Assurez-vous d'augmenter votre *Java Heap Size* (point 2) si vous augmentez significativement le `threadCount`.
  * **Commencez petit :** Une valeur de `50` ou `100` est un bon point de départ pour une instance plus sollicitée. N'allez pas directement à `1000`.
  * **Impact global :** N'oubliez pas que ce pool de threads est partagé pour *tout* : jobs planifiés, exécutions manuelles, commandes ad-hoc, et même les "health checks" des nœuds.

**Redémarrez Rundeck pour appliquer ce changement.**

-----

### 4\. Monitoring JMX (Java Management Extensions)

**🤔 Pourquoi c'est important ?**
Le tuning, c'est bien, mais *monitorer* l'impact de vos changements, c'est mieux \! JMX expose les métriques internes de la JVM et de Rundeck (utilisation mémoire, nombre de threads actifs, etc.).

**🛠️ Comment l'activer ?**
Ajoutez simplement un drapeau au démarrage de la JVM, de la même manière que vous avez ajusté la mémoire (point 2) :

  * **Installation "Launcher" :**
    Dans `$RDECK_BASE/etc/profile`, ajoutez :
    `export RDECK_JVM="$RDECK_JVM -Dcom.sun.management.jmxremote"`

  * **Installation RPM (`/etc/sysconfig/rundeckd`) :**

    ```bash
    RDECK_JVM_SETTINGS="$RDECK_JVM_SETTINGS -Dcom.sun.management.jmxremote"
    ```

  * **Installation DEB (`/etc/default/rundeckd`) :**

    ```bash
    RDECK_JVM_SETTINGS="$RDECK_JVM_SETTINGS -Dcom.sun.management.jmxremote"
    ```

Après redémarrage, vous pouvez vous connecter à la JVM Rundeck en local (sur le serveur lui-même) à l'aide d'un outil comme `jconsole` (fourni avec le JDK).

```bash
# Trouvez le <rundeck_pid> et lancez :
jconsole <rundeck_pid>
```

Cela ouvrira une interface graphique vous montrant l'utilisation de la mémoire, les threads, etc., en temps réel.

-----

### 5\. Optimisation de l'Exécution sur les Nœuds

**SSH intégré :**
Si vous exécutez des commandes sur des *milliers* de nœuds simultanément via le plugin SSH intégré, sachez que cela consomme beaucoup de ressources côté serveur Rundeck (threads, mémoire, CPU pour le chiffrement/déchiffrement).

  * **Exemple de performance (donné dans la doc) :** Sur une machine 8 cœurs / 32Go RAM, un `rpm -q` prenait :
      * 1000 nœuds : \~52 secondes
      * 4000 nœuds : \~3.5 minutes
      * 8000 nœuds : \~7 minutes

La principale limitation est la mémoire JVM par rapport au nombre de threads d'exécution concurrents.

**Alternatives (pour le très haut volume) :**
Si le SSH intégré ne suffit pas, Rundeck peut *déléguer* l'exécution à des outils conçus pour le "fan-out" massif et asynchrone, comme **Ansible (via le plugin Ansible)**, MCollective, ou Salt.

-----

### 6\. Autres Points de Tuning

  * **Performances SSL/HTTPS :** Si vous utilisez HTTPS directement sur Rundeck (Tomcat/Jetty), le chiffrement SSL consomme du CPU. Pour des performances optimales, il est courant de "décharger" le SSL sur un proxy externe (un **load balancer**, **Nginx**, ou **Apache httpd**) qui gère le HTTPS et parle à Rundeck en HTTP simple en interne.

  * **Fournisseurs de Ressources (Resource Provider) :** Si vous chargez vos nœuds depuis une source externe (un script, une API, une CMDB) et que cette source est *lente* à répondre, elle peut ralentoter voire bloquer tout Rundeck (car il attend les données des nœuds). Assurez-vous que vos fournisseurs de ressources sont rapides, asynchrones, et utilisez la **mise en cache** si possible.

-----
