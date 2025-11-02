# Intégration d’Ansible avec Rundeck

## 1) Principales stratégies d’intégration Ansible dans Rundeck
- Commandes locales (CLI) via étapes « Command » ou « Script »  
  Principe: exécuter `ansible`/`ansible-playbook` installés sur le Node d’exécution (server Rundeck ou Node ciblé) avec inventaire et variables fournis via fichiers ou options.  
  Points forts: simplicité, contrôle total des flags; fonctionne avec toute version d’Ansible.  
  Points d’attention: gestion manuelle des chemins, secrets, environnements Python/venv.

- Plugins natifs Ansible pour Rundeck (Node Executor et File Copier, ou plugins Ansible-Runner)  
  Principe: utiliser des étapes dédiées « Ansible Playbook » ou configurer l’exécuteur de nœuds pour Ansible.  
  Points forts: meilleure intégration UI, passage d’inventaire/variables simplifié, logs structurés.  
  Points d’attention: dépend des plugins installés; champs à renseigner précisément.

- API (Webhook ou Job API) déclenchant des orchestrations Ansible externes  
  Principe: Rundeck appelle une API (AWX/Ansible Tower, GitLab CI, Jenkins) qui exécute le playbook, puis récupère le statut.  
  Points forts: séparation des responsabilités, sécurité centralisée, réutilisation d’un contrôleur Ansible.  
  Points d’attention: dépendance externe, gestion des jetons et mapping des paramètres.

- Ansible Runner (local ou via plugin)  
  Principe: empaqueter exécutions via Ansible Runner (répertoires `project/`, `inventory/`, `env/`) pour isolation et reproductibilité.  
  Points forts: exécutions déterministes, intégration simple des secrets via env vars/volumes.  
  Points d’attention: structure projet runner à respecter, packaging/release du contenu.

---

## 2) Tableau comparatif des intégrations
| Critère | Commandes locales | Plugin natif | API (AWX/Tower) | Ansible Runner |
|---|---|---|---|---|
| Simplicité | Haute (si Ansible dispo) | Haute (UI guidée) | Moyenne | Moyenne |
| Sécurité | Variable (shell) | Bonne (scopes) | Excellente (RBAC externe) | Bonne |
| Gestion des secrets | Via Key Storage/ENV | Intégrée Key Storage | Déléguée au contrôleur | Via env/Key Storage |
| Inventaires | Fichiers/inline/args | Champs dédiés | Inventaires gérés côté contrôleur | `inventory/` runner |
| Rôles/Collections | Sur disque/requirements | Champs/plugin | Gérés côté contrôleur | `project/` runner |
| Logs/traçabilité | Stdout | Structurés | Centralisés (API) | Stdout/artefacts |

Remarque: la « meilleure » approche dépend de votre contexte (sécurité, gouvernance, outils existants).

---

## 3) Intégrer playbooks, rôles, secrets et nodes dans un Job Rundeck (par méthode)

A) CLI locale (exec/script)
- Pré-requis: Ansible installé sur le node d’exécution; accès réseau aux cibles; Key Storage pour secrets.
- Étapes typiques: préparer venv/config, installer rôles, récupérer secrets, exécuter `ansible-playbook`.

Exemple de Job YAML (exec) — avec Key Storage pour le vault
```yaml
- defaultTab: nodes
  description: Déploiement applicatif via ansible-playbook (CLI)
  executionEnabled: true
  group: ansible/cli
  loglevel: INFO
  name: deploy_with_cli
  options:
    - name: env
      value: prod
      required: true
      description: Environnement ciblé
    - name: version
      required: true
      description: Version applicative à déployer
    - name: inventory
      required: true
      value: inventories/prod.ini
    - name: limit
      required: false
      description: Filtre d’hôtes Ansible
    - name: playbook
      required: true
      value: playbooks/site.yml
  nodefilters:
    filter: "tags: role:web AND env:${option.env}"
  sequence:
    keepgoing: false
    strategy: node-first
    commands:
      - description: Installer roles/collections
        exec: |
          export ANSIBLE_CONFIG=${project.dir}/ansible.cfg
          ansible-galaxy install -r requirements.yml
      - description: Préparer vault password depuis Key Storage
        file: inline
        script: |
          VAULT_PATH=${option.env == 'prod' ? 'keys/vaults/prod' : 'keys/vaults/nonprod'}
          rd keys get "${VAULT_PATH}" > ${RD_TMPDIR}/.vault
          chmod 600 ${RD_TMPDIR}/.vault
          echo "VAULT_FILE=${RD_TMPDIR}/.vault" >> ${RD_TMPDIR}/env
      - description: Lancer le playbook
        exec: |
          set -e
          source ${RD_TMPDIR}/env || true
          ansible-playbook -i "${option.inventory}" "${option.playbook}" \
            ${option.limit ? "-l '" + option.limit + "'" : ""} \
            -e env=${option.env} -e app_version=${option.version} \
            --vault-password-file "${VAULT_FILE}"
```

Notes pédagogiques
- On installe les rôles avant l’exécution pour garantir la reproductibilité.
- Le secret Vault est récupéré depuis Key Storage via la CLI `rd` et conservé dans un fichier temporaire.
- Le filtre `limit` est optionnel; s’il est vide, Ansible ciblera l’inventaire complet.

B) Plugin natif « Ansible Playbook » (si installé)
- Pré-requis: plugin Ansible pour Rundeck présent et activé au niveau du projet/instance.
- Avantages: champs dédiés (playbook, inventory, extra vars, limit, creds…), logs structurés.

Champs courants de l’étape « Ansible Playbook »
- playbook-path: chemin vers le playbook
- inventory: chemin (ou contenu) d’inventaire
- extra-vars: variables supplémentaires
- limit: filtre d’hôtes
- vault-password, ssh-key-storage-path: secrets via Key Storage

### Exemple avec plugins natifs (Node Executor & File Copier)

Principes :
- Utiliser les étapes dédiées « Ansible Playbook » pour piloter le lancement de playbooks directement depuis l’interface Rundeck.
- Configurer l’exécuteur de nœuds pour qu’il utilise les modules natifs Ansible (Node Executor, File Copier) pour la connexion et la gestion des secrets.

Exemple : Job Rundeck en YAML avec plugin natif Ansible

```yaml
- defaultTab: nodes
  description: Déploiement applicatif via plugin natif Ansible
  executionEnabled: true
  group: ansible/natif
  loglevel: INFO
  name: deploy_with_plugin
  options:
    - name: env
      value: prod
      required: true
      description: Environnement ciblé
    - name: playbook
      value: playbooks/site.yml
      required: true
      description: Chemin du playbook
    - name: inventory
      value: inventories/prod.ini
      required: true
      description: Fichier inventory
    - name: limit
      value: webservers
      required: false
      description: Filtre d’hôtes Ansible
  nodefilters:
    filter: "tags: role:web AND env:${option.env}"
  sequence:
    keepgoing: false
    strategy: node-first
    commands:
      - description: Exécuter le playbook via le plugin natif
        ansible-playbook:
          playbook-path: "${option.playbook}"
          inventory: "${option.inventory}"
          extra-vars: "env=${option.env}"
          limit: "${option.limit}"
          vault-password: "keys/vaults/prod"
          ssh-key-storage-path: "keys/ssh/prod"
```

Explications sur les champs :
- ansible-playbook : étape dédiée du plugin (remplacera exec), permet d’utiliser tous les champs natifs.
- playbook-path : chemin vers le playbook à exécuter.
- inventory : path vers l’inventaire.
- extra-vars : variables supplémentaires pour la session Ansible.
- limit : filtre d’hôtes Ansible pour cibler un sous-ensemble.
- vault-password et ssh-key-storage-path : secrets récupérés via Key Storage Rundeck.

Ce mode offre :
- Une meilleure intégration des logs,
- Un passage simplifié des secrets,
- Une UI dédiée pour renseigner les champs nécessaires à une exécution sûre et reproductible.

C) API vers AWX/Ansible Tower
- Déclenchement d’un Template/job côté contrôleur, passage des variables via API, suivi de statut.

D) Ansible Runner
- Préparer la structure Runner (`project/`, `inventory/`, `env/`), puis appeler l’étape Runner ou le binaire runner.

---

## Annexes: snippets utiles
- Exemple d’inventory INI minimal
```
[webservers]
web1 ansible_host=10.0.0.11
web2 ansible_host=10.0.0.12
```

- requirements.yml (rôles)
```
- src: geerlingguy.nginx
  version: 0.19.3
- src: community.general
  type: collection
  version: 9.2.0
```

- Extra vars JSON (alternative)
```
{
  "env": "prod",
  "app_version": "1.2.3"
}
```
