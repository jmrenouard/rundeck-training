# SOP : Mise à jour mineure de Rundeck
<!-- Procédure pour la mise à jour de Rundeck de la version 4.14.0 vers 4.14.5 -->

---

## Tableau récapitulatif

| Élément | Contenu attendu | Exemple |
|---|---|---|
| Objectif | Finalité concrète de la procédure | « Mettre à jour Rundeck de 4.14.0 vers 4.14.5 pour corriger les vulnérabilités de sécurité » |
| Portée | Limites, contexte, équipes et systèmes concernés | « Équipe DevOps, serveurs PREPROD/PROD, 2h de maintenance » |
| Prérequis | Accès, outils, versions, conditions initiales | « Accès SSH, Java 11+, backup H2, droits sudo » |
| Responsabilités | Rôles et responsabilités par étape | « DevOps Lead valide, SysAdmin exécute, Dev teste » |
| Étapes | Liste ordonnée claire et testée | « 1. Backup 2. Arrêt service 3. Mise à jour 4. Démarrage 5. Tests » |
| Tests/Validation | Checks mesurables de succès/rollback | « Connexion Web UI, jobs existants, API REST, performances » |
| Sécurité | Risques, confidentialité, sécurité opérationnelle | « Backup des clés, validation checksums, rollback testé » |
| Glossaire | Définitions des acronymes et termes | « RD_HOME, WAR, Job Definition, API Token » |

---

## 1. Objectif

- **But** : Mettre à jour Rundeck de la version 4.14.0 vers 4.14.5 pour bénéficier des corrections de bugs et des améliorations de sécurité, tout en maintenant la continuité du service d'automatisation des tâches.
- **Indicateur de réussite** : Rundeck 4.14.5 opérationnel, tous les jobs existants fonctionnels, Web UI accessible, temps d'arrêt < 30 minutes, aucune perte de données.

## 2. Portée

- **Inclus** : Mise à jour du serveur Rundeck principal, migration de la base de données H2, sauvegarde des configurations et jobs, tests de non-régression.
- **Exclus** : Mise à jour des agents Rundeck distants (à faire séparément), modification des jobs existants, mise à jour des plugins tiers non officiels.
- **Environnements** : PREPROD (test), PROD (production).
- **Fenêtre de maintenance** : Dimanche 02:00–04:00 CET (faible activité utilisateurs).

## 3. Prérequis

- **Accès et autorisations** :
  - Compte sudo sur serveurs rundeck-preprod et rundeck-prod
  - Accès SSH avec clés déployées
  - Droits d'écriture sur /opt/rundeck et /var/rundeck
  - Accès au dépôt de packages (yum/apt)

- **Outils/Versions** :
  - Java OpenJDK 11+ (vérifier avec `java -version`)
  - curl 7.68+ pour téléchargement
  - systemctl pour gestion du service
  - pg_dump si PostgreSQL (ou backup H2)

- **Artefacts/Configurations** :
  - Package Rundeck 4.14.5 (.deb ou .rpm selon distribution)
  - Checksums SHA256 officiels pour validation
  - Configurations actuelles dans /etc/rundeck
  - Liste des plugins installés

- **Sauvegardes et points de restauration** :
  - Backup complet de /var/lib/rundeck (H2 database)
  - Backup de /etc/rundeck (configurations)
  - Snapshot VM ou LVM si disponible
  - Export des définitions de jobs critiques

- **Dépendances opérationnelles** :
  - Services externes disponibles (LDAP/AD, bases de données cibles)
  - Espace disque suffisant (minimum 2GB libre)
  - Réseau opérationnel vers repos de packages

## 4. Responsabilités

- **Propriétaire du SOP** : DevOps Lead (Jean Dupont)
- **Exécutant principal** : SysAdmin Senior (Marie Martin)
- **Validation technique** : Ingénieur DevOps (Pierre Durand)
- **Validation métier** : Responsable Ops (Sophie Bernard)
- **Communication** : Chef de projet IT (Luc Moreau)
- **Escalade en cas d'incident** : Directeur IT (Anne Dubois)

## 5. Étapes détaillées

### 1) Préparation et vérifications initiales

- Vérifier l'espace disque disponible : `df -h /opt /var`
- Confirmer la version actuelle : `sudo systemctl status rundeck`
- Valider la connectivité aux services externes
- Notifier les utilisateurs de la maintenance programmée
- **Résultat attendu** : Environnement prêt, utilisateurs informés, pré-requis validés

### 2) Sauvegarde complète

- Arrêter Rundeck : `sudo systemctl stop rundeck`
- Sauvegarder la base de données : `cp -R /var/lib/rundeck/data /backup/rundeck-$(date +%Y%m%d-%H%M)/`
- Sauvegarder les configurations : `tar -czf /backup/rundeck-config-$(date +%Y%m%d).tar.gz /etc/rundeck`
- Exporter les jobs critiques via API : `rd jobs list -f yaml > /backup/jobs-export.yaml`
- Vérifier l'intégrité des sauvegardes
- **Résultat attendu** : Sauvegardes complètes et vérifiées, possibilité de rollback total

### 3) Téléchargement et validation du package

- Télécharger Rundeck 4.14.5 : `wget https://dl.bintray.com/rundeck/rundeck-deb/rundeck-4.14.5-20231115.deb`
- Vérifier le checksum : `sha256sum rundeck-4.14.5-20231115.deb`
- Comparer avec le hash officiel publié sur rundeck.org
- **Résultat attendu** : Package authentique et intègre téléchargé

### 4) Installation de la mise à jour

- Installer le nouveau package : `sudo dpkg -i rundeck-4.14.5-20231115.deb`
- Résoudre les dépendances si nécessaire : `sudo apt-get install -f`
- Vérifier les logs d'installation : `tail -f /var/log/dpkg.log`
- **Résultat attendu** : Package installé avec succès, pas d'erreurs de dépendances

### 5) Migration automatique et démarrage

- Démarrer Rundeck : `sudo systemctl start rundeck`
- Surveiller les logs de démarrage : `tail -f /var/log/rundeck/service.log`
- Attendre la migration automatique de la DB (peut prendre 5-10 min)
- Vérifier le statut du service : `sudo systemctl status rundeck`
- **Résultat attendu** : Service démarré, migration DB réussie, port 4440 en écoute

### 6) Tests de validation fonctionnelle

- Tester la connexion Web UI : https://rundeck.entreprise.com:4440
- Vérifier l'authentification admin
- Lancer un job de test simple (ping ou echo)
- Tester l'API REST : `curl -H "X-Rundeck-Auth-Token: $TOKEN" http://localhost:4440/api/40/system/info`
- Valider les plugins critiques (Ansible, Git, Slack)
- **Résultat attendu** : Tous les tests passent, fonctionnalités critiques opérationnelles

### 7) Communication et documentation

- Notifier la fin de maintenance aux équipes
- Mettre à jour la documentation technique
- Clôturer le ticket de maintenance
- Programmer le monitoring renforcé 48h
- **Résultat attendu** : Équipes informées, documentation à jour, monitoring actif

### 8) Procédure de rollback (en cas de problème)

- **Conditions de déclenchement** : Échec des tests de validation, erreurs critiques dans les logs, jobs ne fonctionnent plus
- **Étapes de rollback** :
  1. Arrêter Rundeck 4.14.5 : `sudo systemctl stop rundeck`
  2. Désinstaller le package : `sudo dpkg -r rundeck`
  3. Restaurer l'ancienne version depuis backup
  4. Restaurer la base de données : `cp -R /backup/rundeck-YYYYMMDD-HHMM/* /var/lib/rundeck/data/`
  5. Redémarrer le service : `sudo systemctl start rundeck`
- **Vérifications post-rollback** : Version 4.14.0 active, tous les jobs fonctionnent, pas de perte de données

## 6. Tests / Validation

- **Smoke tests** :
  - Ping de l'interface Web (HTTP 200)
  - Login administrateur réussi
  - API accessible : GET /api/40/system/info
  - Base de données responsive (< 2s)

- **Tests fonctionnels clés** :
  - Exécution du job "Health Check" avec succès
  - Création/modification/suppression d'un job test
  - Fonctionnement du scheduler (job programmé)
  - Notifications Slack/email opérationnelles

- **Critères d'acceptation mesurables** :
  - Temps de démarrage < 3 minutes
  - Latence API < 500ms
  - Aucune erreur dans service.log après 15min
  - 100% des jobs critiques (n=15) s'exécutent sans erreur

- **Validation par** : DevOps Lead + Responsable Ops

- **Evidences** :
  - Captures d'écran Web UI avec version 4.14.5
  - Logs de migration DB sans erreurs
  - Résultats des tests automatisés
  - Export des métriques de performance

## 7. Points de sécurité / sûreté

- **Gestion des secrets** :
  - Clés et tokens jamais en clair dans les logs
  - Rotation des tokens API post-migration si nécessaire
  - Backup chiffré des configurations sensibles

- **Moindre privilège** :
  - Comptes techniques avec droits minimaux requis
  - Accès SSH temporaire révoqué post-maintenance
  - Audit des connexions durant la fenêtre

- **Continuité/retour arrière** :
  - Procédure de rollback testée en PREPROD
  - RTO < 30 minutes, RPO = 0 (backup T-0)
  - Plan de communication d'urgence activé

- **Conformité** :
  - Traçabilité complète des actions (logs, tickets)
  - Validation à 4 yeux pour actions critiques
  - Archivage sécurisé des logs de migration

- **Sécurité physique/opérationnelle** :
  - Accès au serveur depuis postes autorisés uniquement
  - Sessions SSH enregistrées et auditées
  - Firewall maintenu actif durant l'opération

- **Risques connus et mitigations** :
  - **Risque** : Corruption DB durant migration → **Mitigation** : Backup validated + rollback testé
  - **Risque** : Plugins incompatibles → **Mitigation** : Test PREPROD + liste plugins validés
  - **Risque** : Timeout démarrage → **Mitigation** : Monitoring + escalade automatique

## 8. Glossaire

- **RD_HOME** : Répertoire d'installation Rundeck (/var/lib/rundeck)
- **WAR** : Web Application Archive, format de déploiement Java
- **Job Definition** : Configuration XML/YAML d'une tâche Rundeck
- **API Token** : Clé d'authentification pour accès programmatique
- **Node** : Serveur géré par Rundeck dans l'inventaire
- **Execution** : Instance d'exécution d'un job avec logs et statut
- **Project** : Espace de travail isolé contenant jobs et configurations
- **RTO (Recovery Time Objective)** : Durée maximale acceptable d'interruption
- **RPO (Recovery Point Objective)** : Perte de données maximale acceptable
- **Smoke test** : Test rapide de fonctionnalités critiques post-déploiement

---

### Historique des révisions

- v1.0 — 2024-03-15 — Création du SOP pour mise à jour Rundeck 4.14.0 → 4.14.5
- v1.1 — 2024-03-20 — Ajout procédure rollback détaillée et tests de validation
- v1.2 — 2024-03-25 — Intégration retours d'expérience PREPROD, précisions sécurité
