# Intégration d’Ansible avec Rundeck

Ce document pédagogique présente les stratégies d’intégration d’Ansible dans Rundeck et fournit des exemples concrets (tableaux comparatifs, champs d’interface, et un job YAML complet) pour intégrer playbooks, rôles, secrets et nodes.

---

## 1) Principales stratégies d’intégration Ansible dans Rundeck

- Commandes locales (CLI) via étapes « Command » ou « Script »
  - Principe: exécuter `ansible`/`ansible-playbook` installés sur le Node d’exécution (server Rundeck ou Node ciblé) avec inventaire et variables fournis via fichiers ou options.
  - Points forts: simplicité, contrôle total des flags; fonctionne avec toute version d’Ansible.
  - Points d’attention: gestion manuelle des chemins, secrets, environnements Python/venv.

- Plugins natifs Ansible pour Rundeck (Node Executor et File Copier, ou plugins Ansible-Runner)
  - Principe: utiliser des étapes dédiées « Ansible Playbook » ou configurer l’exécuteur de nœuds pour Ansible.
  - Points forts: meilleure intégration UI, passage d’inventaire/variables simplifié, logs structurés.
  - Points d’attention: dépend des plugins installés; champs à renseigner précisément.

- API (Webhook ou Job API) déclenchant des orchestrations Ansible externes
  - Principe: Rundeck appelle une API (AWX/Ansible Tower, GitLab CI, Jenkins) qui exécute le playbook, puis récupère le statut.
  - Points forts: séparation des responsabilités, sécurité centralisée, réutilisation d’un contrôleur Ansible.
  - Points d’attention: dépendance externe, gestion des jetons et mapping des paramètres.

- Ansible Runner (local ou via plugin)
  - Principe: empaqueter exécutions via Ansible Runner (répertoires `project/`, `inventory/`, `env/`) pour isolation et reproductibilité.
  - Points forts: exécutions déterministes, intégration simple des secrets via env vars/volumes.
  - Points d’attention: structure projet runner à respecter, packaging/release du contenu.

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

Pré-requis communs
- Playbook et rôles versionnés (Git) ou disponibles sur le node d’exécution
- Secrets (SSH, vault, tokens) stockés dans Key Storage Rundeck: `keys/` (private) ou `passwords/`
- Nodes définis via: inventory YAML/INI, Resource Model (projects), ou inline Node filters

A) Commandes locales (CLI)
1. Étape « Command »: `ansible-playbook -i inventories/prod.ini site.yml -l webservers -e @group_vars/all.yml`
2. Variables secrètes: exposer via env depuis Key Storage, ex: option secure « VAULT_PASS » -> export `ANSIBLE_VAULT_PASSWORD_FILE` via script wrapper, ou utiliser `--vault-password-file` pointant vers un fichier temporaire créé depuis Key Storage.
3. Rôles/collections: installer en étape préalable: `ansible-galaxy install -r requirements.yml` (cache dans `.ansible/` ou dossier projet).
4. Nodes: passer `-l` (limit) basé sur un filtre Rundeck `${node.name}` ou options de job.

Exemple de commande:
```
ansible-playbook -i ${option.inventory} ${option.playbook} -l ${option.limit} \
  -e env=${option.env} --vault-password-file ${env.VAULT_FILE}
```

B) Plugin natif « Ansible Playbook » (si installé)
1. Étape « Ansible Playbook »: renseigner « Playbook Path », « Inventory », « Extra Vars », « Limit ».
2. Secrets: lier des champs « SSH Key Storage Path », « Vault Password » à des entrées Key Storage.
3. Rôles: ajouter une étape « Galaxy Install » (selon plugin) ou exécution préalable de `ansible-galaxy`.
4. Nodes: via « Limit/Hosts » ou mapping automatisé depuis le Resource Model.

C) API vers AWX/Ansible Tower
1. Étape « HTTP Request »: POST sur `/api/v2/job_templates/{id}/launch/` avec token.
2. Inventaire/vars: fournis via `extra_vars` et `inventory`/`limit` dans le payload.
3. Secrets: stocker le token dans Key Storage; injecter via header `Authorization: Bearer ${option.token}`.
4. Rôles: gérés côté AWX (job template et project sync).

Exemple payload minimal:
```
{
  "extra_vars": {"env": "prod", "version": "${option.version}"},
  "limit": "webservers"
}
```

D) Ansible Runner
1. Préparer structure runner: `project/` (playbooks), `inventory/`, `env/`.
2. Étape « Command »: `ansible-runner run . -p site.yml -i inventory/hosts --limit webservers -e @env/extravars.json`
3. Secrets: monter en env vars ou fichiers dans `env/` depuis Key Storage.
4. Rôles: présents dans `project/roles` ou via requirements avant exécution.

---

## 4) Champs de l’interface web Rundeck pour un job Ansible

| Champ | Définition | Exemple |
|---|---|---|
| Name | Nom du Job | "Déploiement Web Prod"
| Group | Dossier logique | "ansible/deploy"
| Description | But du job | "Déploie l’application sur webservers"
| Project | Projet Rundeck cible | "training"
| Nodes (Filter) | Sélection des nœuds d’exécution/targets | tags: role:web AND env:prod
| Workflow | Suite d’étapes | 1) Galaxy install 2) Playbook
| Node Executor | Mécanisme d’exécution | SSH/Ansible/Local
| File Copier | Copie de fichiers vers nodes | SCP/Ansible copier
| Options | Paramètres utilisateur | env=prod, version=1.2.3
| Retry | Relance en cas d’échec | 2
| Timeout | Durée max | 30m
| Log level | Verbosité | INFO/DEBUG
| Notification | Webhook/Email à la fin | Email équipe
| ACL/Permissions | Qui peut lancer/voir | team-devops
| Key Storage paths | Secrets référencés | keys/ssh/prod, passwords/vault
| Ansible Playbook Path | Fichier playbook | playbooks/site.yml
| Ansible Inventory | Fichier/inventory inline | inventories/prod.ini
| Extra Vars | Variables extra (`-e`) | env=prod version=${option.version}
| Limit | Hôtes ciblés | webservers
| Vault Password | Secret vault | keys/vaults/prod

Remarque: certains champs n’apparaissent que si les plugins Ansible sont installés.

---

## 5) Exemple complet de Job Rundeck (YAML)

Ce job illustre: options utilisateur, intégration playbook, variables secrètes, multiples rôles et nodes.

```yaml
- defaultTab: nodes
  description: Déploiement applicatif avec Ansible (playbook + secrets + roles)
  executionEnabled: true
  group: ansible/deploy
  loglevel: INFO
  name: deploy_app_prod
  nodeFilterEditable: true
  nodesSelectedByDefault: true
  scheduleEnabled: false
  uuid: 11111111-2222-3333-4444-555555555555
  options:
    - name: env
      required: true
      value: prod
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
