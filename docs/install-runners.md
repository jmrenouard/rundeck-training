# Installation d'un Runner pour communiquer avec Runbook Cloud

Bonjour ! Je vais vous guider pour installer un Runner qui permettra de communiquer avec votre instance Runbook Automation Cloud (anciennement Rundeck Cloud). C'est une excellente question qui mérite une explication détaillée et pédagogique.[1][2]

## Qu'est-ce qu'un Runner et pourquoi en avez-vous besoin ?

Un **Enterprise Runner** est un composant essentiel de l'architecture Runbook Automation qui agit comme un pont sécurisé entre votre instance cloud et vos environnements privés. Le Runner permet :[3][1]

- **L'exécution d'automation dans des réseaux privés** sans avoir à ouvrir des ports SSH ou autres ports sensibles vers l'extérieur[4][3]
- **Une communication sécurisée** par polling (le Runner interroge régulièrement le cluster cloud)[1]
- **L'orchestration de workflows** proche de votre infrastructure cible[5]

## Prérequis techniques

Avant de commencer l'installation, assurez-vous d'avoir:[2][1]

**Sur le serveur qui hébergera le Runner :**
- **Système d'exploitation** : Linux (RHEL, Ubuntu, Debian, Amazon Linux, Oracle Linux) ou Windows Server 2019
- **Java 11 ou Java 17 JRE** installé
- **Ressources minimales recommandées** :
  - 4 Go de RAM (2 Go pour le Heap Java)
  - 2 cœurs CPU
  - 8 Go de stockage
- **Connectivité réseau** : Accès sortant vers votre instance Runbook Cloud sur le port **443 (HTTPS)**[1]

**Dans votre compte Runbook Automation Cloud :**
- Accès administrateur ou permissions suffisantes pour créer des Runners[1]

## Étapes d'installation détaillées

### Étape 1 : Créer le Runner dans l'interface Runbook Cloud

**1.1 Accéder à la gestion des Runners**

Connectez-vous à votre instance Runbook Automation Cloud (https://votre-sous-domaine.runbook.pagerduty.cloud) et :

1. Cliquez sur l'**icône d'engrenage** (System Menu) en haut à droite[6][2]
2. Sélectionnez **"Runner Management"**[2][6]

**1.2 Créer un nouveau Runner**

1. Cliquez sur le bouton **"Create Runner"**[2][1]
2. Donnez un **nom** descriptif à votre Runner (ex: "runner-prod-datacenter-1")
3. Ajoutez une **description** optionnelle
4. Définissez des **tags** pour ce Runner - ces tags sont cruciaux car ils détermineront quels jobs utiliseront ce Runner[1]

   **Conseil pédagogique** : Utilisez des tags représentant l'emplacement ou la fonction, comme `datacenter-paris`, `prod`, `aws-west`, etc.[1]

**1.3 Sélectionner la plateforme**

Choisissez le type de plateforme où vous allez installer le Runner :[2][1]
- **Linux** (la plus courante)
- **Windows**
- **Docker**
- **Kubernetes**

⚠️ **Important** : Une fois la plateforme sélectionnée, vous ne pourrez plus la changer pour ce Runner.[1]

**1.4 Configuration des réplicas (optionnel)**[1]

Décidez si vous souhaitez traiter les réplicas comme éphémères (recommandé pour Kubernetes ou Auto-Scaling Groups).

**1.5 Association au projet**

Sélectionnez le(s) projet(s) Runbook Automation qui pourront utiliser ce Runner.[6][1]

Cliquez sur **"Next"** puis **"Create Runner"**.

### Étape 2 : Télécharger et installer le Runner

Une fois le Runner créé, l'interface affiche les instructions d'installation spécifiques à votre plateforme.

#### Installation sur Linux

**2.1 Télécharger l'artefact Runner**[2][1]

L'interface vous fournit deux options :

**Option A - Via curl (recommandé)** :
```bash
curl -H "X-Rundeck-Auth-Token: VOTRE_API_TOKEN" \
  -o runner-ID_DU_RUNNER.jar \
  https://votre-sous-domaine.runbook.pagerduty.cloud/api/VERSION/runnerManagement/download/TOKEN_DE_TELECHARGEMENT
```

**Option B - Téléchargement manuel** :
Téléchargez le fichier `.jar` directement via l'interface et transférez-le sur votre serveur.

**💡 Astuce pédagogique** : Le fichier téléchargé contient déjà les identifiants de connexion encodés, ce qui facilite grandement l'installation.[2]

**2.2 Transférer le fichier sur votre serveur**

Si vous avez téléchargé le fichier localement :
```bash
scp runner-ID_DU_RUNNER.jar utilisateur@serveur-runner:/opt/runner/
```

**2.3 Lancer le Runner**[2][1]

```bash
cd /opt/runner
java -jar runner-ID_DU_RUNNER.jar
```

**Pour ajuster la mémoire allouée** (recommandé pour les environnements de production) :[7]
```bash
java -Xms4g -Xmx6g -jar runner-ID_DU_RUNNER.jar
```

#### Installation sur Windows

**2.1 Télécharger avec PowerShell**[1]

```powershell
Invoke-WebRequest -Headers @{"X-Rundeck-Auth-Token"="VOTRE_API_TOKEN"} `
  -Uri "https://votre-sous-domaine.runbook.pagerduty.cloud/api/VERSION/runnerManagement/download/TOKEN" `
  -OutFile "runner-ID_DU_RUNNER.jar"
```

**2.2 Lancer le Runner**

```powershell
java -jar runner-ID_DU_RUNNER.jar
```

#### Installation avec Docker

**2.1 Utiliser Docker Compose**[1]

Créez un fichier `docker-compose.yml` :

```yaml
version: '3.9'
services:
  runner:
    image: rundeck/pro-runner:5.9.0  # Utilisez la version appropriée
    environment:
      - RUNNER_RUNDECK_CLIENT_ID=votre-runner-id
      - RUNNER_RUNDECK_SERVER_URL=https://votre-sous-domaine.runbook.pagerduty.cloud
      - RUNNER_RUNDECK_SERVER_TOKEN=votre-api-token
    restart: unless-stopped
```

**2.2 Démarrer le conteneur**

```bash
docker-compose up -d
```

### Étape 3 : Configurer le Runner comme service système (Linux)

Pour que le Runner démarre automatiquement au boot du serveur :[1]

**3.1 Créer un fichier de service systemd**

```bash
sudo nano /etc/systemd/system/runner.service
```

**3.2 Ajouter le contenu suivant** :[1]

```ini
[Unit]
Description=Runbook Automation Runner Service
After=network.target

[Service]
Type=simple
User=rundeck
Group=rundeck
WorkingDirectory=/opt/apps/runner
ExecStart=/usr/bin/java -jar /opt/apps/runner/runner-VOTRE_ID.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**3.3 Activer et démarrer le service**

```bash
sudo systemctl daemon-reload
sudo systemctl enable runner
sudo systemctl start runner
sudo systemctl status runner
```

### Étape 4 : Vérifier la connexion du Runner

**4.1 Vérifier dans l'interface web**[2][1]

1. Retournez dans **Runner Management**
2. Votre Runner doit afficher un statut **"Healthy"** avec une icône verte
3. La colonne **"Last Active"** doit afficher un horodatage récent

**4.2 Statuts possibles** :[8]

| Statut | Signification |
|--------|---------------|
| **Healthy** | Tous les réplicas envoient des heartbeats et sont disponibles |
| **New** | Le Runner a été créé mais n'a pas encore envoyé de heartbeat |
| **Unknown** | Aucun heartbeat reçu depuis 30 secondes |
| **Down** | Aucun heartbeat depuis plus de 120 secondes |
| **Unhealthy** | Au moins un réplica est indisponible mais d'autres fonctionnent |

**4.3 Test de connectivité**[8]

Vous pouvez effectuer un ping manuel :
1. Dans Runner Management, cliquez sur l'onglet **"Replicas"**
2. Sélectionnez **Actions > Ping**
3. Vous devriez recevoir une confirmation de réception

## Configuration avancée

### Configuration proxy (si nécessaire)[7]

Si votre serveur doit passer par un proxy pour accéder à Internet :

**Sans authentification** :
```bash
java -Dmicronaut.http.client.proxy-type=http \
     -Dmicronaut.http.client.proxy-address=proxy.entreprise.com:8080 \
     -jar runner-ID.jar
```

**Avec authentification** :
```bash
java -Dmicronaut.http.client.proxy-type=http \
     -Dmicronaut.http.client.proxy-address=proxy.entreprise.com:8080 \
     -Dmicronaut.http.client.proxy-username=utilisateur \
     -Dmicronaut.http.client.proxy-password=motdepasse \
     -jar runner-ID.jar
```

### Variables d'environnement alternatives[1]

Plutôt que d'encoder les credentials dans le JAR, vous pouvez les définir via des variables :

```bash
export RUNNER_RUNDECK_CLIENT_ID="votre-runner-id"
export RUNNER_RUNDECK_SERVER_URL="https://votre-sous-domaine.runbook.pagerduty.cloud"
export RUNNER_RUNDECK_SERVER_TOKEN="votre-token"
java -jar runner.jar
```

## Configuration des jobs pour utiliser le Runner

Une fois le Runner installé et connecté, configurez vos jobs pour l'utiliser :[2][1]

1. Éditez ou créez un job dans votre projet
2. Dans la section **"Runner"** ou **"Nodes & Runners"**
3. Sélectionnez **"Enter a Tag Filter"**
4. Entrez le tag que vous avez défini lors de la création du Runner
5. Sauvegardez le job

**Exemple de configuration** : Si vous avez tagué votre Runner avec `datacenter-paris`, seuls les jobs avec ce tag utiliseront ce Runner pour leur exécution.[1]

## Résolution des problèmes courants

### Le Runner n'apparaît pas comme "Healthy"

**Causes possibles** :
- **Problème de connectivité réseau** : Vérifiez que le port 443 sortant est ouvert
- **Token incorrect** : Régénérez les credentials du Runner
- **Java non installé** : Vérifiez avec `java -version`

**Solution** :
```bash
# Vérifier les logs du Runner
tail -f /opt/runner/logs/runner.log

# Tester la connectivité
curl -v https://votre-sous-domaine.runbook.pagerduty.cloud
```

### Erreur "Local Executor is disabled"[3]

Dans Runbook Automation Cloud, l'exécution locale de commandes est désactivée par sécurité. Les commandes doivent :
- Être exécutées sur le Runner distant
- Ou être dispatché vers des nœuds via le Runner[3]

### Le Runner utilise trop de mémoire

Ajustez la heap Java :
```bash
java -Xms2g -Xmx4g -jar runner-ID.jar
```

## Bonnes pratiques

1. **Utilisez des tags descriptifs** basés sur la localisation ou la fonction (ex: `prod-aws-east`, `dev-datacenter`)[1]
2. **Déployez plusieurs Runners** avec les mêmes tags pour la haute disponibilité[1]
3. **Surveillez régulièrement** le statut des Runners dans l'interface[8]
4. **Configurez la rotation des logs** pour éviter la saturation du disque[1]
5. **Documentez** quels projets utilisent quels Runners

## Ressources complémentaires

- Documentation officielle : [Creating Runners](https://docs.rundeck.com/docs/administration/runner/runner-installation/creating-runners.html)[1]
- Architecture des Runners : [Runner Overview](https://docs.rundeck.com/docs/administration/runner/runner-overview.html)[4]
- Troubleshooting : [Runner Troubleshooting Guide](https://docs.rundeck.com/docs/administration/runner/troubleshooting.html)

N'hésitez pas si vous avez des questions supplémentaires sur un aspect particulier de l'installation ou de la configuration ! Je suis là pour vous aider à approfondir n'importe quel sujet lié aux Runners et à Runbook Automation.

[1](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/29cde0b2-d80b-45a3-9404-036b7c1072de/all_docs_rundeck.pdf)
[2](https://docs.rundeck.com/docs/administration/runner/runner-installation/creating-runners.html)
[3](https://docs.rundeck.com/docs/about/cloud/)
[4](https://docs.rundeck.com/docs/)
[5](https://docs.rundeck.com/docs/administration/runner/runner-plugins/custom-plugins.html)
[6](https://docs.rundeck.com/docs/administration/runner/runner-management/managing-runners.html)
[7](https://docs.rundeck.com/docs/administration/runner/runner-config.html)
[8](https://docs.rundeck.com/docs/administration/runner/runner-management/node-dispatch.html)
[9](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/9e8e75f2-c42b-427f-8532-4ea5b47d68cf/all_docs_rundeck.txt)
[10](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/3bceddca-08dc-423d-b5c6-1c614697221b/all_docs_ansible.txt)
[11](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/collection_0730b4a6-9cce-45c5-9e3f-aa4b51cdfa2f/e366564d-7018-4a58-80ec-0fb5c203c0c9/pa-deployment-guide.pdf)
[12](https://docs.rundeck.com/docs/learning/howto/configure-gcp-plugins.html)
[13](https://docs.rundeck.com/docs/manual/projects/resource-model-sources/aws.html)
[14](https://docs.rundeck.com/docs/manual/jobs/job-plugins/node-steps/oracle.html)
[15](https://docs.rundeck.com/docs/learning/howto/how2-terra-rd-aws.html)
[16](https://docs.rundeck.com/docs/about/enterprise/)
[17](https://docs.rundeck.com/docs/learning/solutions/automated-diagnostics/automation-actions.html)
[18](https://docs.rundeck.com/docs/learning/getting-started/rba/)
[19](https://stackoverflow.com/questions/76576592/how-do-i-make-rundeck-connect-into-a-cloud-sql-instance-from-cloud-run)
[20](https://osinside.github.io/cloud-builder/cluster_setup_from_scratch/runner_setup.html)
[21](https://octopus.com/docs/getting-started/first-runbook-run)
[22](https://www.exoscale.com/blog/highly-available-gitlab-runners/)
[23](https://learn.microsoft.com/en-us/azure/automation/automation-runbook-execution)
[24](https://www.alibabacloud.com/blog/install-rundeck-server-on-alibaba-cloud_595240)
[25](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)
[26](https://docs.azure.cn/en-us/automation/automation-hrw-run-runbooks)
[27](https://www.devopsschool.com/blog/rundeck-community-vs-rundeck-enterprise-vs-rundeck-cloud/)
[28](https://docs.gitlab.com/ci/runners/provision_runners_google_cloud/)
[29](https://learn.microsoft.com/fr-fr/azure/automation/manage-runbooks)
[30](https://blog.cloudtechner.com/rundeck-automate-your-runbook-449f8a9e2c8a)
[31](https://aws.amazon.com/blogs/devops/deploy-and-manage-gitlab-runners-on-amazon-ec2/)
[32](https://www.it-connect.fr/tuto-rundeck-automatiser-gestion-des-serveurs-linux/)
[33](https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners)
[34](https://support.hpe.com/hpesc/public/docDisplay?docId=a00118854en_us&page=GUID-EF10B1B6-220F-4BE1-AD8D-64F0031B9AC3.html&docLocale=en_US)
[35](https://docs.rundeck.com/docs/learning/getting-started/rba/runner-setup.html)