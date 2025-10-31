# Exécuter des playbooks Ansible avec Rundeck

Bienvenue dans ce guide compédagogique qui vous accompagnera dans l'intégration d'Ansible avec Rundeck ! Nous allons explorer ensemble comment configurer, exécuter et gérer vos playbooks Ansible directement depuis Rundeck, en abordant toutes les facettes techniques importantes.

## Vue d'ensemble de l'intégration Ansible-Rundeck

L'intégration entre Rundeck et Ansible permet de combiner la puissance d'automatisation d'Ansible avec l'interface graphique conviviale de Rundeck. Cette combinaison offre plusieurs avantages majeurs :[1]

- **Interface utilisateur intuitive** pour exécuter des playbooks Ansible sans ligne de commande
- **Contrôle d'accès granulaire** via les ACL de Rundeck
- **Historique d'exécution centralisé** avec logs détaillés
- **Orchestration multi-environnements** facilitée

Rundeck utilise un **plugin Ansible intégré** qui permet d'importer les hôtes depuis l'inventaire Ansible, d'exécuter des modules et des playbooks, et fournit également un node executor et un file copier pour vos projets.[1]

## Configuration initiale de l'environnement

### Prérequis techniques

Avant de commencer, assurez-vous d'avoir :[1]

1. **Rundeck installé** (version 5.16.0 ou supérieure recommandée)
2. **Binaires Ansible installés** sur le serveur Rundeck selon la documentation Ansible
3. **Connectivité SSH** confirmée depuis l'utilisateur `rundeck` vers les endpoints définis dans l'inventaire Ansible

### Configuration de base d'Ansible

Ansible nécessite deux fichiers principaux pour fonctionner :[1]

- **`ansible.cfg`** : fichier de configuration (généralement situé dans `/etc/ansible/`)
- **`hosts`** : fichier d'inventaire où Ansible stocke les nœuds distants (également dans `/etc/ansible/`)

Voici un exemple simple d'inventaire :[1]

```ini
[sshfarm]
192.168.33.20
192.168.33.21
192.168.33.22
```

## Configuration du Node Executor Ansible dans Rundeck

Le Node Executor Ansible permet d'exécuter des commandes via le menu "Commands" de Rundeck ou l'étape "Command" par défaut dans un job.[1]

### Étapes de configuration

1. **Créer un nouveau projet** dans Rundeck
2. Aller dans l'onglet **Default Node Executor** et sélectionner **"Ansible Ad-hoc Node Executor"**
3. Configurer les paramètres suivants :[1]
   - **Executable** : généralement `/bin/bash`
   - **Ansible config path** : chemin vers `ansible.cfg` (ex: `/etc/ansible/ansible.cfg`)
   - Cocher **"Generate Inventory"**
   - **SSH User** : définir l'utilisateur (par défaut `rundeck`)
   - **Authentication** : choisir entre `privatekey` ou `password`
   - **SSH Key File path** ou **Password Storage Path** selon la méthode d'authentification choisie

Le plugin Rundeck-Ansible utilise par défaut l'utilisateur `rundeck` pour se connecter aux nœuds distants de l'inventaire Ansible.[1]

## Ajout de la source de nœuds Ansible

Pour importer les nœuds Ansible dans Rundeck :[1]

1. Aller dans **Project Settings > Edit Nodes...**
2. Cliquer sur **"Add new Node Source +"**
3. Choisir **"Ansible Resource Model Source"**
4. Configurer les paramètres :
   - **Ansible inventory File path** : chemin vers votre inventaire (ex: `/etc/ansible/hosts`)
   - **Ansible config path** : `/etc/ansible/ansible.cfg`
   - **Gather Facts** : recommandé de laisser activé
   - **SSH Connection** : même configuration que pour le Node Executor
5. Cliquer sur **Save**

Les nœuds Ansible apparaîtront dans la section **Nodes** de votre projet Rundeck.[1]

## Méthodes d'exécution des playbooks Ansible

Rundeck offre plusieurs méthodes pour exécuter des playbooks Ansible, chacune avec ses avantages spécifiques.

### 1. Ansible Playbook Inline (Workflow/Node Step)

Cette méthode permet d'exécuter un playbook Ansible défini directement dans Rundeck.[2]

**Configuration** :
- Ajouter une nouvelle étape et sélectionner **"Ansible Playbook Inline"**
- Saisir le contenu du playbook dans la zone de texte
- Respecter la syntaxe YAML d'Ansible

**Exemple de playbook inline** :[1]

```yaml
- name: test playbook
  hosts: all
  tasks:
    - shell: uname -a
      ignore_errors: yes
      register: uname_result
    - debug: 
        msg: "{{ uname_result.stdout }}"
```

**Passage de variables** :
- Utiliser le format `"{{ variable_name }}"` dans le playbook
- Définir les variables dans **"Extra Variables"** (format YAML)
- Les valeurs `option` et `data` sont acceptées[2]
- Alternative : utiliser **"Extra Ansible arguments"** avec `-e "variable_name:value"`

### 2. Ansible Playbook (Fichier sur le système de fichiers)

Cette méthode exécute des fichiers playbook existants depuis le système de fichiers.[2]

**Configuration** :
- Ajouter une étape **"Ansible Playbook"** (Workflow ou Node Step)
- Spécifier le **chemin du fichier playbook** dans la zone de texte "Playbook"
- Exemple : `/chemin/vers/mon/playbook.yml`

**Passage de variables** :
- Même principe que pour Inline : utiliser "Extra Variables" ou "Extra Ansible arguments"
- Définir le format de syntaxe (YAML, JSON, etc.)
- Supporter les valeurs `option` et `data`[2]

### 3. Ansible Module (Exécution de modules individuels)

Pour exécuter directement un module Ansible :[2]

**Configuration** :
- Ajouter une étape **"Ansible Module"**
- Spécifier le **nom du module** (ex: `shell`, `copy`, `apt`)
- Ajouter les **arguments** nécessaires dans la zone "Argument"

**Exemple** : exécuter `pwd` avec le module `command`[2]
- Module : `command`
- Argument : `pwd`

### 4. Exécution locale via Command Step

Cette méthode exécute le playbook **centralement** depuis le serveur Rundeck, évitant les problèmes de filtrage des nœuds.[3]

**Commande exemple** :[3]

```bash
ansible-playbook -i /tmp/ansible/inventory /tmp/ansible/web.yaml \
  -u ubuntu -b --private-key=/tmp/ansible/key.pem
```

**Avantages** :
- Contrôle total sur les arguments Ansible
- Évite les limitations du plugin
- Permet l'utilisation de `serial: 1` pour les redémarrages progressifs[4]
- Utile quand l'ordre d'exécution est critique

## Considérations sur le mode d'exécution

### Execute Locally vs Dispatch to Nodes

Il existe deux approches principales pour exécuter des playbooks Ansible depuis Rundeck :[4]

**Execute Locally** :
- Utilise le **Workflow Step** Ansible Playbook
- Cible les nœuds via l'option `--limit` d'Ansible
- Crée un log Ansible propre avec tous les nœuds regroupés sous chaque étape
- **Limites** : impossible d'utiliser `serial: 1`, problèmes avec les ordres d'exécution critiques

**Dispatch to Nodes** :
- Utilise le **Node Step** Ansible Playbook
- Permet un filtrage facile des nœuds via les tags Rundeck
- Logs Rundeck organisés par nœud
- **Limites** : logs Ansible plus complexes avec des exécutions qui se chevauchent

**Recommandation** : utiliser un mix des deux approches selon vos besoins spécifiques.[4]

## Intégration avec Git et SCM

### Configuration Git Import dans Rundeck

Le plugin Git SCM permet la gestion des jobs en tant que code.[5][6]

**Configuration du Git Import** :[6]
1. Aller dans **Project Settings > Setup SCM**
2. Sélectionner **"Setup" pour Git Import**
3. Configurer :
   - **Base Directory** : dossier local pour cloner le dépôt
   - **Git URL** : 
     - HTTP/HTTPS : `http[s]://user@host.xz[:port]/path/to/repo.git`
     - SSH : `ssh://user@host.xz[:port]/path/to/repo.git`
   - **Branch** : branche à utiliser (ex: `master`, `main`)
   - **Fetch automatically** : activer pour récupération en arrière-plan
   - **Pull automatically** : tire automatiquement les changements distants

**Important** : le SCM Rundeck valide les fichiers YAML comme des **définitions de jobs uniquement**. Les playbooks Ansible et autres fichiers ne seront pas reconnus.[7]

### Stratégie recommandée pour Git

**Approche séparée** (recommandée) :[7]
- Utiliser un **dépôt Git séparé** uniquement pour les jobs Rundeck
- Maintenir les playbooks Ansible dans un autre dépôt
- Utiliser le plugin GitHub Script ou un workflow personnalisé pour récupérer les playbooks depuis Git avant exécution

**Workflow type** :[8]
1. Télécharger les playbooks depuis Git (via script ou plugin)
2. Exécuter le playbook Ansible
3. Optionnel : nettoyer les fichiers téléchargés

## Mise à jour des playbooks depuis Git

### Méthode 1 : Via le plugin Git Resource Model

Bien que ce plugin soit archivé, il illustre le concept de récupération de ressources depuis Git.

### Méthode 2 : Workflow personnalisé

Créer un job Rundeck avec les étapes suivantes :

```bash
# Étape 1 : Clone/Pull du dépôt Git
cd /var/lib/rundeck/playbooks
git pull origin main

# Étape 2 : Exécution du playbook
ansible-playbook -i inventory playbook.yml

# Étape 3 : Optionnel - Nettoyage
# ...
```

### Méthode 3 : Utilisation du GitHub Script Plugin

Le plugin GitHub Script (Enterprise) permet d'exécuter directement des scripts depuis un dépôt GitHub.[9]

**Configuration** :
- Type de step : Workflow Step
- Spécifier le dépôt GitHub
- Indiquer le chemin du playbook
- Authentification via token

## Configuration de l'environnement d'exécution

### Variables d'environnement et contexte

Rundeck fournit plusieurs variables de contexte utilisables dans les jobs :

**Variables projet** :
- `${job.project}` : nom du projet
- `${job.name}` : nom du job
- `${job.group}` : groupe du job

**Variables nœud** :
- `${node.name}` : nom du nœud
- `${node.hostname}` : hostname du nœud
- `${node.username}` : utilisateur SSH

**Variables options** :
- `${option.nom_option}` : valeur d'une option de job

**Variables data** :
- `${data.clé}` : valeur capturée par un log filter ou step précédent

### Configuration de l'escalade de privilèges

Si Ansible utilise `become` pour élever les privilèges :[10]

1. Dans les paramètres du **Default Node Executor**
2. Section **Privilege Escalation**
3. Configurer :
   - **Become** : `Yes`
   - **Become Method** : `sudo`, `su`, etc.
   - **Become User** : utilisateur cible (ex: `root`)
   - **Become Password** : référence au Key Storage si nécessaire

### Optimisation des performances avec l'inventaire YAML

Lorsque **Gather Facts** est désactivé, l'inventaire est lu comme données YAML. Cela évite la validation de connexion, économisant considérablement du temps, CPU et RAM.[1]

**Limites par défaut** :[1]
- **Taille des données** : 10 MB (environ 19 000 nœuds)
- **Max Aliases** : 1000

Ces paramètres peuvent être augmentés si nécessaire dans la configuration de la source de nœuds.

## Utilisation avec Enterprise Runner

### Présentation du Runner

L'Enterprise Runner permet d'exécuter l'automation dans des environnements distants sécurisés.[11][12]

**Architecture** :
- Le Runner est un hub d'exécution distant pour les Node Steps
- Communication HTTPS initiée **depuis le Runner** vers le serveur Rundeck
- Polling toutes les 5 secondes pour vérifier les exécutions à traiter
- Sécurité renforcée : plus besoin d'ouvrir les ports SSH/22 depuis Rundeck

### Configuration Ansible avec Runner

**Image Docker personnalisée avec Ansible** :[11]

```dockerfile
ARG RUNNER_VERSION=5.16.0
FROM rundeckpro/runner:${RUNNER_VERSION}

USER root

# Installer Python, pip et Ansible
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install ansible

# Installer sshpass si nécessaire
# RUN apt-get -y install sshpass

USER runner
```

**Fournir l'inventaire Ansible** :[11]
- **Méthode 1** : passer l'inventaire inline dans la définition du job
- **Méthode 2** : copier les fichiers dans le Dockerfile
  ```dockerfile
  COPY path/ansible.cfg /app/ansible/ansible.cfg
  COPY path/hosts /app/ansible/hosts
  ```
- **Méthode 3** : monter les fichiers comme volumes
  ```bash
  docker run -it \
    -v "$(pwd)/ansible.cfg:/app/ansible/ansible.cfg" \
    -v "$(pwd)/hosts:/app/ansible/hosts" \
    rundeckpro/runner:5.16.0
  ```

### Configuration des sources de nœuds avec Runner

Le Runner peut être utilisé pour découvrir des nœuds dans des environnements non directement accessibles.[13]

**Sources de nœuds supportées** (version 4.16.0+) :[13]
- Ansible Inventory
- VMware
- Kubernetes
- Docker
- File
- Script

**Configuration** :
1. Dans **Edit Nodes**, ajouter une nouvelle Node Source
2. Sélectionner le type (ex: "Ansible Resource Model Source")
3. Cocher l'option **"Execute on Runner"** ou sélectionner le Runner par tag
4. Configurer les paramètres spécifiques (chemins d'inventaire, etc.)

## Gestion des secrets et authentification

### Key Storage dans Rundeck

Rundeck offre un système centralisé de gestion des clés accessible via **Project Settings > Key Storage**.

**Types de clés supportées** :
- **Clés SSH privées** : pour l'authentification sur les nœuds
- **Passwords** : stockés de manière sécurisée
- **Tokens API** : pour l'intégration avec d'autres systèmes

**Utilisation avec Ansible** :
- Référencer une clé SSH : `keys/project/mon-projet/id_rsa`
- Référencer un password : `keys/project/mon-projet/ansible-password`

### Integration avec Enterprise Runner

Le Runner peut récupérer des secrets depuis des gestionnaires de secrets non accessibles directement depuis Rundeck (ex: HashiCorp Vault auto-hébergé).[14]

**Configuration via variables d'environnement** :

```bash
export RUNNER_RUNDECK_STORAGE_VAULT_TYPE=vault-storage
export RUNNER_RUNDECK_STORAGE_VAULT_PATH=keys
export RUNNER_RUNDECK_STORAGE_VAULT_CONFIGURATION_ADDRESS=http://vault:8200
export RUNNER_RUNDECK_STORAGE_VAULT_CONFIGURATION_TOKEN=<token>
export RUNNER_RUNDECK_STORAGE_VAULT_CONFIGURATION_ENGINE_VERSION=2
```

**Sécurité** :
- Les secrets récupérés par un Runner ne sont utilisables **que pour les opérations sur ce Runner**
- Les secrets ne sont **pas envoyés** au serveur Rundeck
- Les secrets sont **masqués dans les logs** (affichés comme `***SECURE***`)

## Bonnes pratiques et recommandations

### Architecture et organisation

**Segmentation de l'inventaire** :[1]
- Diviser les inventaires volumineux en groupes de ~1000 nœuds
- Créer une source de nœuds dédiée pour chaque groupe de 1000 nœuds
- Améliore les performances et la maintenabilité

**Gestion des projets** :
- Un projet Rundeck par environnement (Dev, Test, Prod)
- Utiliser les tags Rundeck pour filtrer les nœuds
- Centraliser la configuration Ansible dans `/etc/ansible/`

### Permissions SSH et sécurité

**Configuration des clés SSH Rundeck** :[10]

Par défaut, Rundeck s'exécute sous l'utilisateur `rundeck` avec ses propres clés SSH dans `/var/lib/rundeck/.ssh/`.[10]

**Options** :
1. **Utiliser les clés SSH de Rundeck** :
   ```bash
   ssh-copy-id -i /var/lib/rundeck/.ssh/id_rsa user@hostname
   ```
   
2. **Utiliser des clés existantes** :
   - Spécifier le chemin dans la configuration du Node Executor
   - Ou référencer une clé depuis le Key Storage

**Escalade de privilèges** :
- Configurer `become` dans la section Privilege Escalation
- Stocker le password become dans le Key Storage si nécessaire
- Aligner la configuration avec celle d'Ansible

### Optimisation des performances

**Cache des nœuds** :[10]
- **Use Asynchronous Cache** : `True`
- **Cache Delay** : NE PAS laisser à 30 secondes !
  - Recommandation : `3600` secondes (1 heure) minimum
  - Pour les grands inventaires : encore plus élevé
  - Un délai trop court cause des problèmes de performance car Rundeck collecte les facts Ansible en continu

**Gather Facts** :
- Activer uniquement si nécessaire
- Considérer l'utilisation du fact caching Ansible
- Pour les environnements volumineux, désactiver et gérer les facts manuellement

### Gestion des erreurs

**Configuration recommandée dans les Node Sources** :[10]
- **Ignore Host Discovery Errors** : `yes`
- Permet de continuer l'importation même si certains hôtes sont inaccessibles

**Dans les jobs** :
- Utiliser **"Keep going on failure"** pour continuer malgré les erreurs sur certains nœuds
- Configurer des Error Handlers pour la gestion personnalisée des erreurs
- Utiliser le step **"Job State Conditional"** pour conditionner l'exécution

## Cas d'usage avancés

### Workflows multi-étapes

Exemple de workflow combinant plusieurs technologies :

1. **Étape 1** : Vérification préalable (script shell)
2. **Étape 2** : Exécution playbook Ansible (déploiement)
3. **Étape 3** : Vérification post-déploiement (script Python)
4. **Étape 4** : Notification (webhook vers Slack/Teams)

### Intégration avec Jenkins

Rundeck et Jenkins s'intègrent bien pour couvrir le cycle Dev-Ops complet :[15]

**Pipeline type** :
1. Jenkins : build, test, packaging
2. Jenkins trigger Rundeck : déploiement via playbook Ansible
3. Rundeck trigger Jenkins : tests d'intégration post-déploiement

**Configuration** :
- Installer le plugin Rundeck dans Jenkins
- Configurer la notification webhook Rundeck vers Jenkins
- Utiliser les Options Providers pour partager les artefacts

### Déploiement progressif (rolling update)

Pour les déploiements nécessitant `serial: 1` :[4]

**Solution** : utiliser l'approche "Execute Locally"
```yaml
- name: Rolling update
  hosts: web_servers
  serial: 1
  tasks:
    - name: Update service
      ...
```

Exécuter via Command Step :
```bash
ansible-playbook -i inventory rolling_update.yml
```

## Dépannage et troubleshooting

### Problèmes courants

**Erreur : "Cannot run program ansible-playbook"** :[16]
- **Cause** : binaires Ansible non installés sur le serveur Rundeck
- **Solution** : installer Ansible sur le serveur Rundeck (`apt-get install ansible`)

**Erreur : connexion SSH échoue** :[10]
- Vérifier que les clés SSH de l'utilisateur `rundeck` sont autorisées sur les nœuds cibles
- Tester manuellement : `sudo -u rundeck ssh user@hostname`
- Vérifier les permissions du dossier `.ssh` et des clés

**Playbook non trouvé** :
- Les chemins doivent être **absolus** ou relatifs au répertoire de base du projet
- Vérifier les permissions de lecture sur le fichier playbook pour l'utilisateur `rundeck`

**Inventaire vide ou nœuds manquants** :
- Vérifier le chemin du fichier inventaire dans la configuration Node Source
- Tester manuellement : `ansible-inventory -i /chemin/inventory --list`
- Vérifier les logs Rundeck : `/var/log/rundeck/service.log`

### Debugging avec les logs

**Activer le debug dans Ansible** :[10]
- Dans "Extra Ansible arguments" : `-vvv` (verbosité maximale)
- Ou définir dans `ansible.cfg` : `verbosity = 3`

**Logs Rundeck importants** :
- `/var/log/rundeck/service.log` : logs principaux du service
- `/var/lib/rundeck/logs/` : logs d'exécution des jobs
- Logs du Runner : `.runner/logs/` dans le répertoire d'exécution

## Ressources et références

### Documentation officielle

- Documentation Rundeck : https://docs.rundeck.com
- Documentation Ansible : https://docs.ansible.com
- Plugin Ansible Rundeck : https://github.com/rundeck-plugins/ansible-plugin[17]
- Enterprise Runner : documentation disponible dans les docs Rundeck[12][13][11]

### Communauté et support

- Forums Rundeck : https://community.theforeman.org
- Reddit Rundeck : r/Rundeck, r/ansible
- GitHub Issues : pour signaler des bugs ou demander des fonctionnalités

### Projets d'exemple

- Projet Welcome Rundeck : inclut des exemples d'intégration Ansible[1]
- ansible-rundeck GitHub : exemples de scripts et Dockerfiles[18]

## Conclusion

L'intégration entre Rundeck et Ansible constitue une solution puissante pour l'automatisation d'infrastructure. Les principales forces de cette combinaison sont :

- **Accessibilité** : interface graphique intuitive pour les équipes non techniques
- **Sécurité** : contrôle d'accès granulaire et gestion centralisée des secrets
- **Traçabilité** : historique complet des exécutions avec logs détaillés
- **Évolutivité** : support des environnements distribués via Enterprise Runner

En suivant les bonnes pratiques décrites dans ce guide, notamment la séparation des inventaires, l'optimisation du cache, et la configuration appropriée de l'authentification SSH, vous pourrez mettre en place une solution d'automatisation robuste et maintenable.

N'oubliez pas que le choix entre "Execute Locally" et "Dispatch to Nodes" dépend de vos cas d'usage spécifiques, et qu'un mix des deux approches est souvent la meilleure stratégie. L'utilisation du SCM Git pour versionner vos jobs Rundeck et d'un dépôt séparé pour vos playbooks Ansible garantira une gestion optimale de votre code d'infrastructure.

Bonne automatisation ! 🚀

[1](https://docs.rundeck.com/docs/learning/howto/using-ansible.html)
[2](https://docs.rundeck.com/docs/manual/jobs/job-plugins/workflow-steps/builtin.html)
[3](https://www.devopsschool.com/blog/rundeck-methods-to-run-ansible-from-rundeck/)
[4](https://stackoverflow.com/questions/60359873/rundeck-with-ansible-execute-locally-or-dispatch-to-nodes)
[5](https://docs.rundeck.com/docs/files/pa-deployment-guide.pdf)
[6](https://docs.rundeck.com/docs/manual/projects/scm/git.html)
[7](https://groups.google.com/g/rundeck-discuss/c/nYExOcU9XHg)
[8](https://www.reddit.com/r/Rundeck/comments/1ax6rsu/rundeck_execute_ansible_playbook_from_git/)
[9](https://docs.rundeck.com/docs/manual/jobs/job-plugins/workflow-steps/github.html)
[10](https://jwkenney.github.io/ansible-rundeck-integration/)
[11](https://docs.rundeck.com/docs/administration/runner/runner-installation/runner-install.html)
[12](https://docs.rundeck.com/docs/administration/runner/using-runners/runner-using.html)
[13](https://docs.rundeck.com/docs/administration/runner/using-runners/runners-for-node-discovery.html)
[14](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/29cde0b2-d80b-45a3-9404-036b7c1072de/all_docs_rundeck.pdf)
[15](https://docs.rundeck.com/docs/learning/howto/howtojenkins.html)
[16](https://freshbrewed.science/2024/05/14/rundeck2.html)
[17](https://github.com/rundeck-plugins/ansible-plugin)
[18](https://github.com/onemarcfifty/ansible-rundeck)
[19](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/9e8e75f2-c42b-427f-8532-4ea5b47d68cf/all_docs_rundeck.txt)
[20](https://docs.ansible.com/ansible/latest/collections/community/general/rundeck_project_module.html)
[21](https://docs.ansible.com/ansible/latest/collections/community/general/rundeck_job_run_module.html)
[22](https://docs.rundeck.com/docs/rd-cli/commands.html)
[23](https://github.com/orgs/rundeck-plugins/repositories)
[24](https://docs.ansible.com/ansible/latest/collections/community/general/rundeck_job_executions_info_module.html)
[25](https://docs.rundeck.com/docs/manual/plugins/full-list.html)
[26](https://docs.rundeck.com/docs/about/introduction.html)
[27](https://docs.rundeck.com/docs/)
[28](https://docs.rundeck.com/docs/history/5_x/version-5.5.0.html)
[29](https://galaxy.ansible.com/ui/repo/published/community/general/content/module/git_config/)
[30](https://docs.rundeck.com/docs/manual/jobs/job-plugins/)
[31](https://stackoverflow.com/questions/76962884/rundeck-version-control-with-ansible)
[32](https://www.reddit.com/r/ansible/comments/18ghrj8/integrating_ansible_core_with_rundeck_for/)
[33](https://ansible.readthedocs.io/projects/runner/en/latest/execution_environments/)
[34](https://sulek.fr/index.php?article87%2Fexecution-environments-et-ansible)
[35](https://github.com/rundeck/rundeck/issues/8712)
[36](https://community.theforeman.org/t/how-good-is-that-making-ansible-and-rundeck-work-together/9014)
[37](https://blog.stephane-robert.info/post/rundeck-ansible-gerer-votre-infrastructure/)