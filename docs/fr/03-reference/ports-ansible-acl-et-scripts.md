# Ports, Ansible, ACLPolicy et scripts

## Services Docker (`docker/`)

| Fichier | Services / Images | Ports et volumes par défaut |
| :--- | :--- | :--- |
| `docker/docker-compose.yml` | `rundeck/rundeck:4.17.6`, `mysql:8.0` | `RUNDECK_PORT=4440`, `MYSQL_PORT=3306`, `./rundeck-data`, `./mysql-data` |
| `docker/docker-swarm.yml` | `rundeck/rundeck:4.17.6`, `mysql:8.0` (`replicas: 1`) | Contraintes manager, volumes nommés `rundeck-data`, `mysql-data` |
| `docker/.env.example` | Modèle d'environnement | `RUNDECK_GRAILS_URL`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` |
| `docker/Makefile` | Commandes | `up`, `down`, `logs`, `ps`, `restart`, `swarm-deploy`, `swarm-rm`, `swarm-services`, `clean`, `help` |

## Ansible et Générateurs Web

- **Playbooks (`ansible/playbooks/`):** `site.yml` (`java`, `mysql`, `rundeck`, `keycloak`, `minio`), `java.yml`, `mysql.yml`, `rundeck.yml`, `nginx.yml`, `keycloak.yml`, `minio.yml`
- **Rôles (`ansible/roles/`):** `java`, `mysql`, `rundeck` (`5.3.0.20240813-1`, port `4440`), `nginx`, `keycloak`, `minio`
- **Outils web :** `aclpolicy/index.html`, `ressources/index.html`, `jobs/index.html`, `propertyfile/index.html` (`plaintext`, `OBF`, `MD5`, `BCRYPT`)

## Templates et Scripts

- **Templates (`templates/` et `docker/jobs/`):** `68` fichiers YAML sous `templates/` (`linux/`, `windows/`, `rundeck/`) plus `docker/jobs/sample-job.yml`
- **Scripts (`scripts/`):** `install_ubuntu.sh`, `install_docker_env.sh`, `install_java.sh`, `install_mysql.sh`, `install_rundeck.sh`, `install_rundeck_enterprise.sh`, `install_rundeck_runner.sh`, `install_nginx.sh`, `install_certbot.sh`, `install_minio.sh`, `install_gemini.sh`, `backup_rundeck.sh`, `restore_rundeck.sh`, `tuning_linux.sh`, `site_to_pdf.sh`, `crawl_site.py`
