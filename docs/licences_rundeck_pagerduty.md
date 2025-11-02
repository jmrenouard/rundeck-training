# Licences PagerDuty et Rundeck - Guide Complet

## Introduction

Ce document présente un guide complet des différents modèles de licences disponibles pour PagerDuty (On-premise et SaaS) et Rundeck, avec des tableaux récapitulatifs et des formules de calcul de coût.

---

## 1. Définitions des Licences

### 1.1 PagerDuty SaaS (Software as a Service)

**Définition :** Service hébergé dans le cloud de PagerDuty, accessible via navigateur web ou applications mobiles.

**Caractéristiques principales :**
- Infrastructure gérée par PagerDuty
- Mises à jour automatiques
- Haute disponibilité garantie (SLA 99.9%+)
- Sécurité et conformité gérées par PagerDuty
- Facturation par utilisateur/mois
- Déploiement rapide (minutes à heures)

### 1.2 PagerDuty On-Premise

**Définition :** Version installée et hébergée sur l'infrastructure de l'entreprise cliente.

**Caractéristiques principales :**
- Contrôle total de l'infrastructure
- Personnalisation avancée possible
- Conformité aux politiques de sécurité internes
- Gestion des mises à jour par l'entreprise
- Facturation par licence perpétuelle + maintenance
- Temps de déploiement plus long (semaines à mois)

### 1.3 Rundeck Open Source

**Définition :** Version communautaire gratuite de Rundeck, sous licence Apache 2.0.

**Caractéristiques principales :**
- Gratuit et open source
- Fonctionnalités de base d'automatisation
- Support communautaire
- Pas de SLA officiel
- Hébergement et maintenance à la charge de l'utilisateur

### 1.4 Rundeck Enterprise

**Définition :** Version commerciale de Rundeck avec fonctionnalités avancées et support professionnel.

**Caractéristiques principales :**
- Fonctionnalités avancées (RBAC, clustering, etc.)
- Support technique professionnel
- SLA défini par contrat
- Facturation par nœud géré
- Mises à jour et correctifs prioritaires

---

## 2. Tableau Récapitulatif des Types de Licences

| Critère | PagerDuty SaaS | PagerDuty On-Premise | Rundeck Open Source | Rundeck Enterprise |
|---------|----------------|----------------------|---------------------|--------------------|
| **Modèle de déploiement** | Cloud hébergé | On-premise | Auto-hébergé | Auto-hébergé ou cloud |
| **Coût initial** | Aucun | Élevé | Gratuit | Moyen |
| **Modèle de facturation** | Abonnement mensuel | Licence + maintenance | Gratuit | Licence annuelle |
| **Maintenance** | Incluse | Optionnelle | Communautaire | Incluse |
| **Support** | 24/7 selon plan | 24/7 selon contrat | Communautaire | Professionnel 24/7 |
| **Sécurité** | Gérée par PagerDuty | Gérée par client | Gérée par client | Gérée par client |
| **Personnalisation** | Limitée | Élevée | Élevée | Élevée |
| **Temps de déploiement** | Immédiat | 4-12 semaines | 1-4 semaines | 2-6 semaines |
| **Évolutivité** | Automatique | Manuelle | Manuelle | Semi-automatique |
| **Conformité** | SOC2, ISO27001 | Selon implémentation | Selon implémentation | Support conformité |

---

## 3. Tableau des Tarifs et Paramètres Principaux

### 3.1 PagerDuty SaaS - Tarification 2024

| Plan | Prix/Utilisateur/Mois (USD) | Utilisateurs Inclus | Fonctionnalités Clés |
|------|----------------------------|--------------------|-----------------------|
| **Starter** | 21 $ | Minimum 5 | Alertes de base, intégrations limitées |
| **Professional** | 41 $ | Minimum 5 | Workflows automatisés, API complète |
| **Business** | 61 $ | Minimum 10 | Analytics avancés, business services |
| **Enterprise** | Sur devis | Variable | SSO, support prioritaire, formations |

**Options supplémentaires :**
- Modern Incident Response : +19$/utilisateur/mois
- Event Intelligence : +9$/utilisateur/mois
- Runbook Automation : +15$/utilisateur/mois

### 3.2 PagerDuty On-Premise - Tarification 2024

| Composant | Prix Unitaire (USD) | Unité de Mesure | Notes |
|-----------|---------------------|-----------------|-------|
| **Licence de base** | 150 000 $ | Par instance | Jusqu'à 100 utilisateurs |
| **Utilisateur supplémentaire** | 500 $ | Par utilisateur/an | Au-delà de 100 utilisateurs |
| **Maintenance annuelle** | 25% du prix licence | Par an | Support et mises à jour |
| **Services professionnels** | 2 000 $/jour | Par consultant | Installation et formation |
| **Formation** | 5 000 $ | Par session | Jusqu'à 20 participants |

### 3.3 Rundeck - Tarification 2024

| Version | Prix/Nœud/An (USD) | Minimum de Nœuds | Fonctionnalités Incluses |
|---------|-------------------|------------------|--------------------------|
| **Open Source** | 0 $ | Illimité | Fonctionnalités de base |
| **Enterprise** | 50 $ | 25 nœuds | RBAC, clustering, support |
| **Enterprise Plus** | 75 $ | 50 nœuds | Workflow designer, analytics |
| **Enterprise Premium** | 100 $ | 100 nœuds | Toutes fonctionnalités, support prioritaire |

**Services additionnels :**
- Support Premium : +25% du coût des licences
- Services professionnels : 2 500 $/jour
- Formation : 3 000 $/session (jusqu'à 15 participants)

---

## 4. Formules de Calcul de Coût

### 4.1 PagerDuty SaaS

#### Formule de base :
```
Coût Annuel = (Prix par utilisateur × Nombre d'utilisateurs × 12) + Options
```

#### Exemple de calcul :
```
Scénario : 25 utilisateurs, Plan Professional + Modern Incident Response

Coût de base = 41$ × 25 utilisateurs × 12 mois = 12 300 $
Option MIR = 19$ × 25 utilisateurs × 12 mois = 5 700 $
Coût Total Annuel = 12 300 $ + 5 700 $ = 18 000 $
```

### 4.2 PagerDuty On-Premise

#### Formule année 1 :
```
Coût Année 1 = Licence de base + (Utilisateurs supplémentaires × Prix unitaire) + Services
```

#### Formule années suivantes :
```
Coût Annuel = (Coût total des licences × 25%) + Services additionnels
```

#### Exemple de calcul :
```
Scénario : 150 utilisateurs

Année 1 :
Licence de base = 150 000 $ (100 premiers utilisateurs)
Utilisateurs supplémentaires = 50 × 500 $ = 25 000 $
Services professionnels = 10 jours × 2 000 $ = 20 000 $
Coût Année 1 = 150 000 $ + 25 000 $ + 20 000 $ = 195 000 $

Années suivantes :
Maintenance = (150 000 $ + 25 000 $) × 25% = 43 750 $
Coût Annuel Récurrent = 43 750 $
```

### 4.3 Rundeck Enterprise

#### Formule de base :
```
Coût Annuel = (Nombre de nœuds × Prix par nœud) + Support + Services
```

#### Avec support premium :
```
Coût avec Support Premium = Coût Annuel + (Coût des licences × 25%)
```

#### Exemple de calcul :
```
Scénario : 200 nœuds, Enterprise Plus avec support premium

Coût des licences = 200 nœuds × 75 $ = 15 000 $
Support premium = 15 000 $ × 25% = 3 750 $
Coût Total Annuel = 15 000 $ + 3 750 $ = 18 750 $
```

---

## 5. Calculateur de Coût Rapide

### Variables à définir :
- **N_users** = Nombre d'utilisateurs
- **N_nodes** = Nombre de nœuds à gérer
- **Plan** = Type de plan choisi
- **Options** = Fonctionnalités supplémentaires
- **Support** = Niveau de support souhaité

### Formules résumées :

```
# PagerDuty SaaS
PD_SaaS_Annual = (Plan_Price × N_users × 12) + (Options_Price × N_users × 12)

# PagerDuty On-Premise (Année 1)
PD_OnPrem_Y1 = 150000 + max(0, (N_users - 100) × 500) + Professional_Services

# PagerDuty On-Premise (Années suivantes)
PD_OnPrem_Recurring = Total_Licenses × 0.25

# Rundeck Enterprise
Rundeck_Annual = max(N_nodes, Minimum_Nodes) × Node_Price × (1 + Support_Multiplier)
```

---

## 6. Recommandations par Scénario

### Petite entreprise (< 50 utilisateurs, < 100 nœuds)
- **Recommandé :** PagerDuty SaaS Starter + Rundeck Open Source
- **Coût estimé :** 12 600 $ + 0 $ = 12 600 $/an

### Moyenne entreprise (50-200 utilisateurs, 100-500 nœuds)
- **Recommandé :** PagerDuty SaaS Professional + Rundeck Enterprise
- **Coût estimé :** 49 200 $ + 25 000 $ = 74 200 $/an

### Grande entreprise (> 200 utilisateurs, > 500 nœuds)
- **Recommandé :** PagerDuty Enterprise + Rundeck Enterprise Plus
- **Coût estimé :** Sur devis + 37 500 $+

### Environnement hautement sécurisé
- **Recommandé :** PagerDuty On-Premise + Rundeck Enterprise Premium
- **Coût estimé :** Variable selon infrastructure

---

## 7. Facteurs de Décision

### Choisir PagerDuty SaaS si :
- Déploiement rapide requis
- Budget prévisible souhaité
- Équipe IT limitée
- Intégrations multiples nécessaires

### Choisir PagerDuty On-Premise si :
- Contraintes de sécurité strictes
- Données sensibles ne pouvant quitter l'infrastructure
- Personnalisations importantes requises
- Budget d'investissement disponible

### Choisir Rundeck Open Source si :
- Budget très limité
- Équipe technique expérimentée
- Besoins d'automatisation simples
- Acceptation du support communautaire

### Choisir Rundeck Enterprise si :
- Environnement de production critique
- Besoins de support professionnel
- Fonctionnalités avancées requises
- ROI justifié par l'automatisation

---

## Conclusion

Le choix entre ces différentes options dépend principalement de :
1. **La taille de l'organisation**
2. **Les contraintes de sécurité et conformité**
3. **Le budget disponible (CAPEX vs OPEX)**
4. **L'expertise technique interne**
5. **Les besoins en support et formation**

Il est recommandé de réaliser une évaluation pilote avant tout déploiement en production, particulièrement pour les solutions on-premise qui nécessitent un investissement initial important.

---

*Document créé à des fins pédagogiques - Les tarifs peuvent évoluer, consultez les sites officiels pour les prix actuels.*
