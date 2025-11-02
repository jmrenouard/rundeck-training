# Template SOP (Standard Operating Procedure)

<!-- Ce modèle sert de base pour décrire une procédure opérationnelle standard. Remplacez chaque commentaire par vos informations. -->

---

## Tableau récapitulatif

| Élément | Contenu attendu | Exemple |
|---|---|---|
| Objectif | Finalité concrète de la procédure | « Déployer l’application X en production » |
| Portée | Limites, contexte, équipes et systèmes concernés | « Équipe Ops, environnements PREPROD/PROD » |
| Prérequis | Accès, outils, versions, conditions initiales | « Accès SSH, Docker 24.x, droits admin » |
| Responsabilités | Rôles et responsabilités par étape | « Ops valide, Dev fournit artefacts » |
| Étapes | Liste ordonnée claire et testée | « 1. … 2. … 3. … » |
| Tests/Validation | Checks mesurables de succès/rollback | « Smoke tests, métriques, critères d’acceptation » |
| Sécurité | Risques, confidentialité, sécurité opérationnelle | « Secrets, rollback sécurisé, accès moindres » |
| Glossaire | Définitions des acronymes et termes | « RTO, RPO, Artefact, Smoke test » |

---

## 1. Objectif

<!-- Décrire en une ou deux phrases la finalité de ce SOP, le résultat attendu et la valeur métier. Soyez spécifique et mesurable. -->

- But: <!-- ex: Déployer la version X de l’application Y en environnement PROD de manière fiable et répétable. -->
- Indicateur de réussite: <!-- ex: Service disponible, latence < 200 ms, erreurs < 1%. -->

## 2. Portée

<!-- Préciser ce qui est inclus et exclus, ainsi que les équipes, systèmes, environnements et fenêtres de service. -->

- Inclus: <!-- ex: Déploiement backend + migration DB sur PROD. -->
- Exclus: <!-- ex: Déploiement mobile, mises à jour front indépendantes. -->
- Environnements: <!-- ex: PREPROD, PROD. -->
- Fenêtre de maintenance: <!-- ex: Dimanche 22:00–23:00 CET. -->

## 3. Prérequis

<!-- Lister de façon vérifiable tout ce qui est nécessaire avant d’exécuter les étapes. Spécifier versions, accès, configurations et sauvegardes. -->

- Accès et autorisations: <!-- ex: Compte admin sur Kubernetes, accès au registre d’images. -->
- Outils/Versions: <!-- ex: kubectl 1.30, helm 3.14, jq 1.7. -->
- Artefacts/Configurations: <!-- ex: Image docker app:1.2.3 signée, fichiers values.yaml. -->
- Sauvegardes et points de restauration: <!-- ex: Snapshot base de données T-1h validé. -->
- Dépendances opérationnelles: <!-- ex: CDN opérationnel, secrets présents dans le vault. -->

## 4. Responsabilités

<!-- Assigner clairement « qui fait quoi » et « qui approuve quoi ». -->

- Propriétaire du SOP: <!-- Nom/Rôle -->
- Exécutant principal: <!-- Nom/Rôle -->
- Relecteur/Validateur: <!-- Nom/Rôle -->
- Support/astreinte: <!-- Nom/Rôle + contact -->
- Sécurité/Conformité: <!-- Nom/Rôle -->

## 5. Étapes détaillées du SOP

<!-- Décrire une procédure reproductible en liste ordonnée. Chaque étape doit être atomique, vérifiable, avec résultat attendu. Inclure commandes ou captures si nécessaire. -->

1) Préparation
   - <!-- Vérifier la santé des services, espace disque, quotas, feature flags. -->
   - Résultat attendu: <!-- ex: Tous les préchecks passent. -->

2) Mise en maintenance (si applicable)
   - <!-- Activer page de maintenance / drainer le trafic / cordonner les nœuds. -->
   - Résultat attendu: <!-- ex: Trafic à 0 sur l’ancienne version. -->

3) Déploiement
   - <!-- Lancer le déploiement/rollback planifié, ex: helm upgrade --install ... -->
   - Résultat attendu: <!-- ex: Pods READY=1/1, migrations terminées sans erreur. -->

4) Vérifications post-déploiement
   - <!-- Exécuter smoke tests, vérifier logs, métriques, endpoints /healthz. -->
   - Résultat attendu: <!-- ex: Taux d’erreur < seuil, SLA respecté. -->

5) Rétablissement du trafic
   - <!-- Réactiver le routage, enlever la maintenance, réouvrir le circuit breaker. -->
   - Résultat attendu: <!-- ex: 100% du trafic sur la nouvelle version sans régression. -->

6) Communication et documentation
   - <!-- Informer parties prenantes, mettre à jour le changelog, tickets, runbook. -->
   - Résultat attendu: <!-- ex: Ticket clôturé, documentation à jour. -->

7) Rollback (procédure de repli) — optionnel mais recommandé
   - Conditions de déclenchement: <!-- ex: KPI non conformes au bout de 10 min. -->
   - Étapes de rollback: <!-- ex: helm rollback release n-1; restaurer snapshot DB. -->
   - Vérifications post-rollback: <!-- ex: Service revenu au niveau nominal. -->

## 6. Tests / Validation

<!-- Définir des tests objectifs de conformité/succès. Indiquer qui valide et comment tracer. -->

- Smoke tests: <!-- ex: Ping de 5 endpoints critiques, code 200. -->
- Tests fonctionnels clés: <!-- ex: Scénarios commande/paiement OK. -->
- Critères d’acceptation mesurables: <!-- ex: Erreurs < 1%, latence P95 < 200 ms. -->
- Validation par: <!-- ex: Lead Ops + Product Owner. -->
- Evidences: <!-- ex: Captures Grafana, logs, lien rapport CI. -->

## 7. Points de sécurité / sûreté

<!-- Lister risques, contrôles, secrets, contraintes réglementaires et consignes de sécurité opérationnelle. -->

- Gestion des secrets: <!-- ex: Jamais en clair; rotation après déploiement. -->
- Moindre privilège: <!-- ex: Comptes techniques avec rôles dédiés. -->
- Continuité/retour arrière: <!-- ex: Backups testés, plan de reprise. -->
- Conformité: <!-- ex: RGPD, traçabilité des accès et actions. -->
- Sécurité physique/opérationnelle: <!-- ex: Accès restreint aux consoles PROD. -->
- Risques connus et mitigations: <!-- ex: Timeout DB; paramétrer pool et retries. -->

## 8. Glossaire

<!-- Définir les acronymes et termes métier/techniques pour lever toute ambiguïté. -->

- Artefact: <!-- ex: Paquet déployable (image Docker, binaire). -->
- Smoke test: <!-- ex: Test rapide de non-régression critique. -->
- RTO / RPO: <!-- ex: Objectifs de reprise en temps/perte de données. -->
- SLA / SLO: <!-- ex: Engagements/objectif de niveau de service. -->
- Runbook: <!-- ex: Guide d’exploitation détaillé lié à un incident/activité. -->

---

### Historique des révisions

<!-- Tenir à jour les évolutions de ce SOP. -->

- v0.1 — <!-- AAAA-MM-JJ — Création du document. -->
- v0.2 — <!-- AAAA-MM-JJ — Ajustements post-retour d’expérience. -->
