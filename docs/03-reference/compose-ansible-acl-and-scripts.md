# Compose, Ansible, ACLPolicy, Templates & Scripts

## Docker Compose & Swarm Matrix (`docker/`)

| Asset | Services / Images | Default Ports & Volumes |
| :--- | :--- | :--- |
| `docker/docker-compose.yml` | `rundeck/rundeck:4.17.6`, `mysql:8.0` | `RUNDECK_PORT=4440`, `MYSQL_PORT=3306`, `./rundeck-data`, `./mysql-data` |
| `docker/docker-swarm.yml` | `rundeck/rundeck:4.17.6`, `mysql:8.0` (`replicas: 1`) | Manager constraints, named volumes `rundeck-data`, `mysql-data` |
| `docker/.env.example` | Environment template | `RUNDECK_GRAILS_URL`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` |
| `docker/Makefile` | Management wrapper | `up`, `down`, `logs`, `ps`, `restart`, `swarm-deploy`, `swarm-rm`, `swarm-services`, `clean`, `help` |

## Ansible Roles & Playbooks (`ansible/`)

- **Configuration:** `ansible/ansible.cfg`, `ansible/inventory/hosts`
- **Playbooks:** `site.yml` (full stack), `java.yml`, `mysql.yml`, `rundeck.yml`, `nginx.yml`, `keycloak.yml`, `minio.yml`
- **Roles:** `java`, `mysql`, `rundeck`, `nginx`, `keycloak`, `minio`
- **Rundeck defaults (`ansible/roles/rundeck/defaults/main.yml`):** `rundeck_version: "5.3.0.20240813-1"`, `rundeck_port: "4440"`, `rundeck_db_name: "rundeck"`, `rundeck_service: "rundeckd"` (requires encrypted vault `rundeck_db_password`)

## Web Configuration Utilities

| Directory | Files | Output / Supported Formats |
| :--- | :--- | :--- |
| `aclpolicy/` | `index.html`, `README.md` | Multi-document `.aclpolicy` YAML (`context`, `for`, `by`, `notBy`) |
| `ressources/` | `index.html`, `README.md` | Node inventory `resources.yml` YAML mapping |
| `jobs/` | `index.html`, `README.md` | Multi-step Rundeck job YAML (`exec`, `script`, `jobref`, `scriptfile`, `scripturl`) |
| `propertyfile/` | `index.html`, `bcrypt.min.js`, `README.md`, `README.en.md` | `realm.properties` (`plaintext`, `OBF`, `MD5`, `BCRYPT`) |

## Job Templates (`templates/`, `docker/jobs/`)

- **Root & Sample Templates:** `docker/jobs/sample-job.yml`, `templates/ansible_job_template.yaml`, `templates/bash_job_template.yaml`, `templates/python_job_template.yaml`
- **Linux Categories (`templates/linux/`):** `ansible/`, `backup/`, `deployment/`, `maintenance/`, `reporting/`, `security/`, `webhooks/`
- **Windows Categories (`templates/windows/`):** `backup/`, `deployment/`, `maintenance/`, `reporting/`, `security/`
- **Rundeck Specialized (`templates/rundeck/`):** `minio/transfert-s3.yml`, `reporting/job-rundeck-reporting-html-execution-status.yaml`

## Shell & Python Automation (`scripts/`)

- **Installers:** `install_ubuntu.sh`, `install_docker_env.sh`, `install_java.sh`, `install_mysql.sh`, `install_rundeck.sh`, `install_rundeck_enterprise.sh`, `install_rundeck_runner.sh`, `install_nginx.sh`, `install_certbot.sh`, `install_minio.sh`, `install_gemini.sh`
- **Operations & Docs:** `backup_rundeck.sh`, `restore_rundeck.sh`, `tuning_linux.sh`, `site_to_pdf.sh`, `crawl_site.py`
