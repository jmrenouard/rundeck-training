# Exempels d'usage de rundeck_cli

Voici 30 commandes essentielles du client Rundeck CLI rd, avec un exemple d’usage à chaque fois pour t’entraîner rapidement.

### Pré requis
- Définis RDURL et un mode d’authentification (token ou user/pass) avant d’exécuter rd, par exemple: export RDURL="https://rundeck.example.com" et export RDTOKEN="xxxxx".

### Aide et configuration
1) Afficher l’aide globale  
- Commande: rd --help  
- Exemple: rd --help.

2) Afficher la version du CLI  
- Commande: rd --version  
- Exemple: rd --version.

3) Configurer l’URL et le token via variables  
- Commande: export RDURL="https://rundeck:4440" ; export RDTOKEN="xxxxx"  
- Exemple: export RDURL="https://rundeck:4440" ; export RDTOKEN="xxxxx".

4) Fichier de conf rd (.rdrd.conf)  
- Commande: export RDCONF="$HOME/.rdrd.conf"  
- Exemple: echo 'RDURL=https://rundeck:4440' >> ~/.rdrd.conf.

5) Activer debug HTTP  
- Commande: export RDDEBUG=2  
- Exemple: RDDEBUG=2 rd projects list.

### Projets
6) Lister les projets  
- Commande: rd projects list  
- Exemple: rd projects list.

7) Créer un projet  
- Commande: rd projects create -p MONPROJET  
- Exemple: rd projects create -p demo-ops.

8) Supprimer un projet  
- Commande: rd projects delete -p MONPROJET  
- Exemple: rd projects delete -p demo-ops.

9) Afficher la config d’un projet  
- Commande: rd projects configure get -p MONPROJET  
- Exemple: rd projects configure get -p anvils.

10) Modifier une propriété de projet  
- Commande: rd projects configure set -p MONPROJET -- --project.ssh-keypath /home/rundeck/.ssh/id_rsa  
- Exemple: rd projects configure set -p MyProject -- --project.ssh-keypath /home/rundeck/.ssh/id_rsa.

### Nœuds
11) Lister les nœuds avec filtre  
- Commande: rd nodes -p MONPROJET -F 'tags:www'  
- Exemple: rd nodes -p anvils -F 'tags:www'.

12) Lister en combinant filtres  
- Commande: rd nodes -p MONPROJET -F 'tags:wwwapp'  
- Exemple: rd nodes -p anvils -F 'tags:wwwapp'.

13) Exclure des nœuds  
- Commande: rd nodes -p MONPROJET -F '!tags:db'  
- Exemple: rd nodes -p anvils -F '!tags:www,app'.

### Exécution ad‑hoc
14) Exécuter une commande ad‑hoc  
- Commande: rd adhoc -p MONPROJET -F 'tags:www' -- 'whoami'  
- Exemple: rd adhoc -p anvils -F 'tags:www' -- 'id'.

15) Suivre la sortie en temps réel  
- Commande: rd adhoc -p MONPROJET --follow -F 'tags:www' -- 'whoami'  
- Exemple: rd adhoc -p anvils --follow -F 'tags:www' -- 'whoami'.

### Jobs: découverte et export/import
16) Lister les jobs d’un projet  
- Commande: rd jobs list -p MONPROJET  
- Exemple: rd jobs list -p anvils.

17) Exporter les jobs en YAML  
- Commande: rd jobs list -p MONPROJET --file jobs.yaml -F yaml  
- Exemple: rd jobs list -p anvils --file out/jobs.yaml -F yaml.

18) Importer des jobs (YAML/JSON/XML)  
- Commande: rd jobs load -p MONPROJET --file jobs.yaml -F yaml  
- Exemple: rd jobs load -p anvils --file jobs.yaml -F yaml.

19) Afficher un job par UUID  
- Commande: rd jobs info --id <UUID>  
- Exemple: rd jobs info --id 4f1a….

20) Rechercher des jobs par nom/groupe  
- Commande: rd jobs list -p MONPROJET -g 'web' -n 'Restart'  
- Exemple: rd jobs list -p anvils -g 'web' -n 'Restart'.

### Jobs: exécution
21) Démarrer un job par nom  
- Commande: rd run -p MONPROJET -j 'GROUPE/NOM' -- -opt1 val1  
- Exemple: rd run -p anvils -j 'web/Restart' -- -method normal.

22) Démarrer un job par UUID  
- Commande: rd run --id <UUID> -- -opt1 val1  
- Exemple: rd run --id 4f1a… -- -method force.

23) Suivre l’exécution  
- Commande: rd run -p MONPROJET --follow -j 'GROUPE/NOM'  
- Exemple: rd run -p anvils --follow -j 'web/Restart'.

### Exécutions
24) Lister les exécutions d’un projet  
- Commande: rd executions list -p MONPROJET  
- Exemple: rd executions list -p anvils.

25) Voir les détails d’une exécution  
- Commande: rd executions info -e <ID>  
- Exemple: rd executions info -e 148.

26) Télécharger le log d’une exécution  
- Commande: rd executions output -e <ID> --file out.log  
- Exemple: rd executions output -e 148 --file out.log.

27) Arrêter/abandonner une exécution en cours  
- Commande: rd executions kill -e <ID>  
- Exemple: rd executions kill -e 148.

### Stockage de clés
28) Lister les entrées de Key Storage  
- Commande: rd storage list /keys  
- Exemple: rd storage list /keys.

29) Importer une clé privée dans le Key Storage  
- Commande: rd storage upload /keys/id_rsa --file ~/.ssh/id_rsa --type privateKey --chmod 600  
- Exemple: rd storage upload /keys/proj/id_rsa --file ~/.ssh/id_rsa --type privateKey --chmod 600.

30) Lire une donnée “password” depuis le Key Storage  
- Commande: rd storage get /keys/db/password --type password --out -  
- Exemple: rd storage get /keys/db/password --type password --out -.

### Bonus: ACL en ligne de commande
- Tester une règle ACL: rd acl test --context project -p MONPROJET -g ops -A --allow run  
- Exemple: rd acl test --context application -g apitokengroup -s keys/key1.pem --allow read.
