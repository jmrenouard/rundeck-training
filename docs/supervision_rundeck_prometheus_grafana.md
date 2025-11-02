# Supervision Rundeck avec Prometheus et Grafana

Ce guide décrit, de bout en bout, comment superviser un cluster/serveur Rundeck avec rundeck_exporter, Prometheus et Grafana. Il couvre l’installation, la configuration, ainsi que l’import des tableaux de bord Grafana.

---

## 1. Concepts et architecture

- Rundeck: orchestrateur d’automatisation. Expose des métriques système et d’exécutions via API.
- rundeck_exporter: service (Python) qui interroge l’API Rundeck et expose des métriques au format Prometheus sur un port HTTP (par défaut 9620).
- Prometheus: collecte périodiquement les métriques (scrape) depuis l’exporter et les stocke en TSDB.
- Grafana: visualise les métriques Prometheus via des dashboards préconstruits.

Flux: Rundeck API -> rundeck_exporter (http://exporter:9620) -> Prometheus (scrape) -> Grafana (dashboards)

---

## 2. Prérequis

- Accès administrateur à l’instance Rundeck (ou un compte avec droits lecture étendus + token API).
- Python 3.10+ (si installation bare-metal de l’exporter) ou Docker/Compose.
- Accès réseau: Prometheus doit joindre l’exporter; Grafana doit joindre Prometheus.
- Activer les métriques côté Rundeck si version >= 4.x (voir section 3.3).

---

## 3. Installation de rundeck_exporter

### 3.1 Options d’installation

- Python (pip): installation flexible, simple pour VM/bare-metal.
- Docker: image unique exposant le port 9620.
- Docker Compose: stack prête avec Rundeck, exporter, Prometheus et Grafana.

Références: phsmith/rundeck_exporter (GPL-3.0) – contient exemples de dashboards et docker-compose.

### 3.2 Déploiement via Python (bare‑metal)

1) Installer dépendances:
```
pip install prometheus-client requests cachetools
```
2) Récupérer le code de l’exporter (git clone ou archive) puis lancer:
```
export RUNDECK_TOKEN=<votre_token>
python rundeck_exporter.py \
  --host 0.0.0.0 \
  --port 9620 \
  --rundeck.url https://rundeck.example.com \
  --rundeck.skip_ssl \
  --rundeck.api.version 34 \
  --rundeck.cpu.stats \
  --rundeck.memory.stats \
  --rundeck.projects.executions \
  --rundeck.projects.executions.filter 5n
```
3) Vérifier l’endpoint:
```
curl -s http://localhost:9620 | head -n 50
```

### 3.3 Spécificités Rundeck >= 4.x (activation métriques)

Depuis Rundeck 4.x, l’endpoint /api/<version>/metrics est désactivé par défaut. Activer au choix:
- Dans rundeck-config.properties: metrics.enabled=true
- Ou par variable d’environnement: RUNDECK_METRICS_ENABLED=true

Voir documentation officielle Rundeck (config-file-reference.html#metrics-capturing).

### 3.4 Droits API et ACL minimaux

Créer un token pour un utilisateur (ex: exporter) avec au minimum:
- system:read (contexte system)
- project:read (contexte system)
- events:read (contexte project)
- node:read (contexte project)

Exemple de politique ACL (extrait):
```
by:
  username: exporter
for:
  resource:
  - allow: [read]
    equals: { kind: system }
context:
  application: rundeck
---
by:
  username: exporter
for:
  project:
  - allow: [read]
    match: { name: ".*" }
context:
  application: rundeck
---
by:
  username: exporter
for:
  resource:
  - allow: [read]
    equals: { kind: event }
  job:
  - allow: [read, view]
context:
  project: .*
---
by:
  username: exporter
for:
  node:
  - allow: [read]
    match: { nodename: ".*" }
context:
  project: .*
```

### 3.5 Variables d’environnement utiles (exporter)

- RUNDECK_URL: URL base Rundeck (requis)
- RUNDECK_TOKEN: token d’accès (requis si pas d’auth basique)
- RUNDECK_USERNAME / RUNDECK_USERPASSWORD: alternatives au token
- RUNDECK_API_VERSION: par défaut 34 (selon votre version)
- RUNDECK_SKIP_SSL: true pour ignorer la validation TLS
- RUNDECK_PROJECTS_EXECUTIONS: true pour activer les métriques d’exécutions
- RUNDECK_PROJECTS_FILTER: liste d’espaces séparés
- RUNDECK_PROJECT_EXECUTIONS_FILTER: fenêtre (ex: 5n, 1h, 1d)
- RUNDECK_PROJECTS_EXECUTIONS_LIMIT: 20 par défaut
- RUNDECK_PROJECTS_EXECUTIONS_CACHE: true/false
- RUNDECK_PROJECTS_NODES_INFO: true/false (peut charger le CPU)
- RUNDECK_CACHED_REQUESTS_TTL: 120s par défaut
- RUNDECK_CPU_STATS / RUNDECK_MEMORY_STATS: true/false
- RUNDECK_EXPORTER_HOST: 0.0.0.0, RUNDECK_EXPORTER_PORT: 9620
- RUNDECK_EXPORTER_NO_CHECKS_IN_PASSIVE_MODE: true/false
- RUNDECK_EXPORTER_THREADPOOL_MAX_WORKERS: défaut = CPU+4
- RUNDECK_EXPORTER_REQUESTS_TIMEOUT: 30s par défaut

### 3.6 Exemples Docker

Build local et run:
```
docker build -t rundeck_exporter .
docker run --rm -d -p 9620:9620 \
  -e RUNDECK_TOKEN=$RUNDECK_TOKEN \
  rundeck_exporter \
  --host 0.0.0.0 \
  --rundeck.url https://rundeck.example.com \
  --rundeck.skip_ssl
```

Compose (exemple):
- Services: Rundeck (4440), Exporter (9620), Prometheus (9090), Grafana (3000)
- Après provisionning: générer un token dans Rundeck (Profile > API Tokens), placer dans docker-compose.yml, puis `docker compose up -d`.

---

## 4. Configuration Prometheus

### 4.1 Ajout d’un job de scrape

Dans prometheus.yml:
```
scrape_configs:
  - job_name: 'rundeck'
    scrape_interval: 15s
    static_configs:
      - targets: ['exporter.example.local:9620']
```

Variantes:
- Avec file_sd_configs ou service discovery (Consul, Kubernetes) si dynamique.
- Ajoutez labels pour l’instance/cluster si vous avez plusieurs Rundeck.

### 4.2 Bonnes pratiques

- Timeout de scrape < RUNDECK_EXPORTER_REQUESTS_TIMEOUT.
- Aligner scrape_interval avec la fraîcheur nécessaire (ex: 15s–60s).
- Si plusieurs exporters: utiliser relabel_configs pour labels instance.

---

## 5. Dashboards Grafana

### 5.1 Source de données

- Créer une datasource Prometheus pointant vers http://prometheus:9090.

### 5.2 Import de dashboards

- Depuis le repo de l’exporter: exemples dans examples/grafana.
- Méthodes:
  1) UI Grafana: Dashboards > Import > Import JSON, puis coller le contenu du JSON d’exemple.
  2) API Grafana: POST /api/dashboards/db avec un payload JSON (nécessite un token Grafana).

### 5.3 Contenu typique des dashboards

- Santé système Rundeck: rundeck_system_info, rundeck_system_stats_*, CPU/Mem process.
- Scheduler/Quartz: rundeck_scheduler_quartz_*.
- Exécutions par projet: rundeck_project_executions_total, rundeck_project_execution_status, rundeck_project_execution_duration_seconds, rundeck_project_start_timestamp.
- Caches/Services: rundeck_services_*.

---

## 6. Exemples de requêtes PromQL

- Exécutions totales par projet:
```
sum by(project_name) (rundeck_project_executions_total)
```
- Taux d’échecs sur 1h:
```
sum by(project_name) (increase(rundeck_services_ExecutionService_executionFailureMeter_total[1h]))
  / sum by(project_name) (increase(rundeck_services_ExecutionService_executionStartMeter_total[1h]))
```
- Durée moyenne d’exécution (gauge mise à jour fin d’exécution):
```
avg by(project_name) (rundeck_project_execution_duration_seconds)
```
- Nombre de jobs planifiés:
```
max(rundeck_scheduler_quartz_scheduledJobs)
```

---

## 7. Alerting (exemples rapides)

- Exporter down:
```
ALERT RundeckExporterDown
  IF up{job="rundeck"} == 0
  FOR 2m
  LABELS { severity = "critical" }
  ANNOTATIONS { summary = "Rundeck exporter injoignable" }
```
- Taux d’échecs élevé:
```
ALERT RundeckHighFailureRate
  IF (increase(rundeck_services_ExecutionService_executionFailureMeter_total[15m])
     / clamp_min(increase(rundeck_services_ExecutionService_executionStartMeter_total[15m]), 1)) > 0.3
  FOR 10m
  LABELS { severity = "warning" }
```

---

## 8. Tableau de paramètres et configuration

| Composant | Paramètre/Variable | Valeur par défaut | Description |
|---|---|---|---|
| Exporter | RUNDECK_URL | — | URL base Rundeck (requis) |
| Exporter | RUNDECK_TOKEN | — | Token API (requis si pas d’auth utilisateur) |
| Exporter | RUNDECK_API_VERSION | 34 (selon doc) | Version API Rundeck |
| Exporter | RUNDECK_SKIP_SSL | false | Ignore la vérification TLS |
| Exporter | RUNDECK_PROJECTS_EXECUTIONS | false | Active métriques d’exécutions |
| Exporter | RUNDECK_PROJECT_EXECUTIONS_FILTER | 5n | Fenêtre pour dernières exécutions |
| Exporter | RUNDECK_PROJECTS_EXECUTIONS_LIMIT | 20 | Limite par requête |
| Exporter | RUNDECK_PROJECTS_EXECUTIONS_CACHE | false | Mise en cache des requêtes |
| Exporter | RUNDECK_PROJECTS_NODES_INFO | false | Compte des nœuds par projet |
| Exporter | RUNDECK_CACHED_REQUESTS_TTL | 120 | TTL du cache (s) |
| Exporter | RUNDECK_CPU_STATS / MEMORY_STATS | false | Expose CPU/Mémoire du process |
| Exporter | RUNDECK_EXPORTER_HOST | 127.0.0.1 | Adresse d’écoute |
| Exporter | RUNDECK_EXPORTER_PORT | 9620 | Port d’écoute |
| Exporter | RUNDECK_EXPORTER_REQUESTS_TIMEOUT | 30 | Timeout requêtes API (s) |
| Prometheus | scrape_interval | 15s | Fréquence de collecte |
| Prometheus | targets | — | hosts:ports des exporters |
| Grafana | Datasource URL | — | URL Prometheus (ex: http://prometheus:9090) |

---

## 9. Dépannage

- 404/401 sur l’exporter: vérifier RUNDECK_URL, token et ACL.
- Pas de métriques “metrics/*” en 4.x: activer RUNDECK_METRICS_ENABLED.
- Latence élevée: réduire fenêtres d’exécutions, activer le cache, ajuster threadpool_max_workers.
- SSL: utiliser --rundeck.skip_ssl en test, ou charger la CA.
- Multiples instances Rundeck: déployer un exporter par instance et labeliser dans Prometheus.

---

## 10. Références

- Exporter: https://github.com/phsmith/rundeck_exporter (exemples Grafana et docker-compose)
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/
- Rundeck API & configuration: documentation officielle (metrics, API token, ACL)
