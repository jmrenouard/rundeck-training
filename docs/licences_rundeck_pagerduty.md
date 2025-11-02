# Licences PagerDuty et Rundeck - Guide Complet

## Introduction

Ce document présente un guide complet des différents modèles de licences disponibles pour PagerDuty (On-premise et SaaS) et Rundeck, avec des tableaux récapitulatifs et des formules de calcul de coût.

---

## 1. Définitions et Principes des Versions Rundeck

Voici un récapitulatif didactique des trois versions principales de Rundeck, leurs licences et leurs cas d'usage.

### 1.1 Rundeck Community Edition

**Licence :** Apache v2.0 (open source, gratuit)

**Usage :** Automatisation pour équipes de petite/moyenne taille

**Support :** Pas de support professionnel, communauté uniquement

**Téléchargement :** Gratuit sur le site officiel

**Caractéristiques principales :**
- Licence très permissive permettant l'utilisation libre, modification et redistribution
- Idéale pour tests, développement, usage interne
- Fonctionnalités de base d'automatisation
- Hébergement et maintenance à la charge de l'utilisateur
- Pas de SLA officiel

### 1.2 Rundeck Enterprise / Pro / Runbook Automation

**Licence :** Commerciale, vendue par PagerDuty

**Usage :** Automatisation à l'échelle entreprise, fonctionnalités avancées

**Support :** Accès au support officiel PagerDuty + mises à jour prioritaires

**Fonctionnalités additionnelles :**
- Haute disponibilité (clustering, HA)
- ACL améliorées, gestion avancée des rôles (RBAC)
- Tableaux de bord enrichis, plugins exclusifs
- SSO, LDAP/Active Directory
- Sécurité accrue, audits et conformité
- Garanties de maintien et conformité cruciales pour production

**Installation :** Via fichier de licence à uploader ou déposer sur le serveur (voir section gestion de licence)

### 1.3 Rundeck Cloud

**Licence :** SaaS, abonnement commercial

**Usage :** Plateforme managée, accès instantané sans gestion d'infrastructure

**Support :** Géré par PagerDuty avec niveau de disponibilité élevé

**Caractéristiques principales :**
- Mises à jour automatiques
- Infrastructure gérée par PagerDuty
- Haute disponibilité garantie
- Sécurité et conformité gérées
- Différents rôles administrateurs comparé à l'édition Enterprise locale
- Déploiement rapide (minutes)
- Licence embarquée automatiquement

---

## 2. Tableau Comparatif des Versions & Licences

| Version | Licence | Prix | Support | Fonctionnalités clés | Utilisation recommandée |
|---------|---------|------|---------|---------------------|-------------------------|
| **Community / Open Source** | Apache v2.0 | Gratuit | Communauté | Automatisation, jobs, plugins OSS | Équipes techniques, test, développement |
| **Enterprise / Pro** | Commerciale PagerDuty | Payant* | Professionnel | HA, clustering, plugins exclusifs, RBAC avancé, SSO | Production, besoins avancés, conformité |
| **Cloud (SaaS)** | Abonnement commercial | Payant** | Professionnel | Mises à jour auto, sécurité gérée, infrastructure managée | Entreprise, devops cloud, déploiement rapide |

**Tarifs indicatifs*** :
- **Enterprise/Pro** : D'après certains témoignages, environ $20k/cluster + $1k/utilisateur/an
- À comparer à d'autres solutions payantes comme Ansible Tower (tarif au nœud)
- **Cloud** : Modèle à l'utilisateur ou à l'instance

---

## 3. Installation et Gestion de Licence Enterprise

### 3.1 Méthodes d'Installation de la Licence

La licence Enterprise (`rundeckpro-license.key`) peut être installée de plusieurs façons :

**Option 1 : Via l'interface graphique (GUI)**
- Uploader le fichier de licence directement via l'interface web de Rundeck
- Méthode recommandée pour les débutants

**Option 2 : Dépôt manuel du fichier**
- Placer le fichier `rundeckpro-license.key` dans `/etc/rundeck/` (selon l'OS)
- Redémarrer le service Rundeck

**Option 3 : Stockage avancé**
- Configuration dans la base de données
- Stockage dans un storage tree (ex : Amazon S3)
- Options configurables selon l'architecture

### 3.2 Particularités SaaS/Cloud

- La version SaaS/Cloud embarque la licence automatiquement
- Pas de gestion manuelle de fichier de licence nécessaire
- Activation immédiate lors de la souscription

---

## 4. Versions Supportées en 2025

Rundeck publie régulièrement des versions majeures. Les versions actuellement en support (fin 2025) sont :

- **5.16.0** (octobre 2025)
- **5.15.0** (septembre 2025)
- **5.14.1 / 5.14.0** (août 2025)
- **5.13.0** (juin 2025)

**Politique de support** : Les versions sont généralement supportées jusqu'à 1 an après leur sortie.

**Recommandation** : Maintenir à jour votre installation avec les versions supportées pour bénéficier des correctifs de sécurité et du support technique.

---

## 5. Points Pédagogiques sur les Modèles de Licence

### 5.1 Licence Apache v2.0 (Open Source)

**Avantages :**
- Très permissive : utilisation libre, modification et redistribution autorisées
- Idéale pour tests, développement, usage interne
- Aucun coût de licence
- Transparence du code source

**Limitations :**
- Pas de support professionnel
- Fonctionnalités limitées comparé à l'édition Enterprise
- Pas de garantie de disponibilité (SLA)

### 5.2 Licence Commerciale (Enterprise/Pro)

**Avantages :**
- Garanties de maintien et conformité
- Support technique professionnel crucial pour la production
- Fonctionnalités avancées indispensables pour les entreprises
- SLA défini par contrat

**Fonctionnalités clés pour l'entreprise :**
- **HA/Clustering** : Haute disponibilité indispensable pour forte exigence de disponibilité
- **Plugins exclusifs** : Intégrations avancées non disponibles en open source
- **ACL et RBAC** : Contrôle d'accès fin pour la sécurité et la conformité
- **Monitoring avancé** : Tableaux de bord enrichis et métriques détaillées
- **SSO/LDAP/Active Directory** : Intégration avec les systèmes d'authentification d'entreprise

### 5.3 Modèle SaaS (Cloud)

**Quand choisir le SaaS ?**
- Déploiement rapide requis
- Pas de ressources pour gérer l'infrastructure
- Besoin de haute disponibilité garantie
- Mises à jour automatiques souhaitées

**Considérations :**
- Coût récurrent à l'utilisateur
- Dépendance au fournisseur cloud
- Moins de personnalisation que l'on-premise

---

## 6. Définitions des Licences PagerDuty

### 6.1 PagerDuty SaaS (Software as a Service)

**Définition :** Service hébergé dans le cloud de PagerDuty, accessible via navigateur web ou applications mobiles.

**Caractéristiques principales :**
- Infrastructure gérée par PagerDuty
- Mises à jour automatiques
- Haute disponibilité garantie (SLA 99.9%+)
- Sécurité et conformité gérées par PagerDuty
- Facturation par utilisateur/mois
- Déploiement rapide (minutes à heures)

### 6.2 PagerDuty On-Premise

**Définition :** Version installée et hébergée sur l'infrastructure de l'entreprise cliente.

**Caractéristiques principales :**
- Contrôle total de l'infrastructure
- Personnalisation avancée possible
- Conformité aux politiques de sécurité internes
- Gestion des mises à jour par l'entreprise
- Facturation par licence perpétuelle + maintenance
- Temps de déploiement plus long (semaines à mois)
