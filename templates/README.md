# Documentation des Templates Rundeck

Ce répertoire contient des templates de jobs pour Rundeck, prêts à l'emploi pour différentes technologies. Chaque template est fourni au format YAML et peut être importé directement dans votre projet Rundeck.

## Contenu

- [`ansible_job_template.yaml`](#template-job-ansible)
- [`bash_job_template.yaml`](#template-job-bash)
- [`python_job_template.yaml`](#template-job-python)

---

### Template Job Ansible

Le fichier `ansible_job_template.yaml` est un template pour un job Rundeck qui exécute un playbook Ansible.

**Caractéristiques :**
- Exécute un playbook Ansible spécifié.
- Configure l'inventaire, l'utilisateur SSH, et la clé privée.
- Gère l'escalade de privilèges (`become`).
- Envoie des notifications par email en cas de succès ou d'échec.

**Utilisation :**
1. Personnalisez les chemins d'accès au playbook, à l'inventaire et à la clé SSH.
2. Adaptez les informations de notification (destinataires, etc.).
3. Importez le fichier YAML dans votre projet Rundeck.

---

### Template Job Bash

Le fichier `bash_job_template.yaml` est un template pour un job Rundeck qui exécute une série de commandes Bash.

**Caractéristiques :**
- Workflow séquentiel avec trois étapes de commandes Bash.
- Le job s'arrête si une étape échoue.
- Envoie des notifications par email en cas de succès ou d'échec.

**Utilisation :**
1. Modifiez les commandes `exec` dans chaque étape pour correspondre à vos besoins.
2. Configurez les notifications.
3. Importez le fichier YAML dans Rundeck.

---

### Template Job Python

Le fichier `python_job_template.yaml` est un template pour un job Rundeck qui exécute des scripts Python.

**Caractéristiques :**
- Exécute des scripts Python directement dans les étapes du job.
- Workflow séquentiel en trois étapes.
- Le job s'arrête en cas d'échec d'une étape.
- Notifications par email pour le suivi du statut du job.

**Utilisation :**
1. Remplacez le contenu des balises `script` par votre code Python.
2. Ajustez les paramètres de notification.
3. Importez le fichier YAML dans votre projet Rundeck.