# Introduction à la Gestion des Secrets

## Sur Cette Page
- [Options de Stockage dans Rundeck et Runbook Automation](#options-de-stockage-dans-rundeck-et-runbook-automation)
- [Stockage de Clés Rundeck](#stockage-de-clés-rundeck)
- [Intégration avec Hashicorp Vault](#intégration-avec-hashicorp-vault)
- [Options de Stockage Supplémentaires dans PagerDuty Runbook Automation](#options-de-stockage-supplémentaires-dans-pagerduty-runbook-automation)
- [Intégration avec Thycotic Secret Server](#intégration-avec-thycotic-secret-server)
- [Intégration avec Cyberark Privileged Access](#intégration-avec-cyberark-privileged-access)
- [Comment fonctionne le Stockage de Clés avec les outils tiers ?](#comment-fonctionne-le-stockage-de-clés-avec-les-outils-tiers-)
- [Exemple Pratique : Comment utiliser un Secret pour s'authentifier auprès de nœuds distants](#exemple-pratique--comment-utiliser-un-secret-pour-s-authentifier-auprès-de-nœuds-distants)
- [Ressources](#ressources)

Alors que les organisations comptent de plus en plus sur Rundeck, il devient crucial de prioriser le stockage sécurisé des clés cryptographiques. De bonnes pratiques de stockage de clés sont fondamentales pour protéger les informations sensibles, sécuriser les systèmes critiques et renforcer la posture de sécurité globale. En consolidant les clés dans un référentiel centralisé, les organisations peuvent appliquer des politiques de sécurité cohérentes, contrôler l'accès, surveiller l'utilisation des clés et maintenir des journaux d'audit.

Rundeck utilise un stockage de clés intégré pour sauvegarder toutes les informations d'identification liées aux nœuds distants (ou à d'autres fins). Il est également possible de l'intégrer avec d'autres technologies de gestion de secrets de premier plan comme Hashicorp Vault, Cyberark Privileged Access et Thycotic Secret Server.

L'interface pour télécharger une clé dans le keystore de Rundeck.

## Options de Stockage dans Rundeck et Runbook Automation

### Stockage de Clés Rundeck
Le Stockage de Clés Rundeck est l'espace que les administrateurs Rundeck peuvent utiliser pour stocker des données sensibles de clés privées/mots de passe ("clés") qui peuvent être utilisées à travers Rundeck. Par défaut, Rundeck stocke ces clés dans la base de données interne. Ces clés peuvent être utilisées pour personnaliser les plugins de l'environnement d'automatisation, les exécuteurs de nœuds et d'autres composants.

Rundeck dispose également du Chiffrement du Stockage de Clés. Cela permet de chiffrer les clés et les mots de passe enregistrés dans le Stockage de Clés Rundeck (au niveau du backend Rundeck). Le paramètre suivant active ce chiffrement et est prédéfini dans le fichier `rundeck-config.properties` :
```properties
# Chiffrement pour le stockage de clés
rundeck.storage.provider.1.type=db
rundeck.storage.provider.1.path=keys
rundeck.storage.converter.1.type=jasypt-encryption
rundeck.storage.converter.1.path=keys
rundeck.storage.converter.1.config.encryptorType=custom
rundeck.storage.converter.1.config.password=encryption_password
rundeck.storage.converter.1.config.algorithm=PBEWITHSHA256AND128BITAES-CBC-BC
rundeck.storage.converter.1.config.provider=BC
```

### Intégration avec Hashicorp Vault
HashiCorp Vault est un outil open-source très réputé qui fournit une solution centralisée et sécurisée pour la gestion des secrets, des clés de chiffrement et des données sensibles dans les environnements informatiques modernes. Agissant comme une plateforme robuste de gestion des secrets, Vault offre une large gamme de fonctionnalités, y compris le stockage de secrets, la génération de secrets dynamiques, des contrôles d'accès sécurisés et le chiffrement en tant que service.

## Options de Stockage Supplémentaires dans PagerDuty Runbook Automation

### Intégration avec Thycotic Secret Server
Thycotic Secret Server est une solution de Gestion des Accès à Privilèges (PAM) conçue pour sécuriser et rationaliser la gestion des secrets sensibles et des informations d'identification à privilèges au sein des organisations. Il fournit un référentiel centralisé pour stocker et gérer les secrets, y compris les mots de passe, les clés SSH, les informations d'identification de base de données et les jetons d'API.

### Intégration avec Cyberark Privileged Access
CyberArk est un fournisseur de solutions de sécurité des accès à privilèges, offrant une suite complète de produits conçus pour protéger et gérer les comptes, les informations d'identification et les secrets à privilèges au sein des organisations. Le produit phare de CyberArk, CyberArk Privileged Access Security, aide les organisations à sécuriser, surveiller et contrôler l'accès à privilèges aux systèmes et données critiques.

## Comment fonctionne le Stockage de Clés avec les outils tiers ?
Si vous utilisez un outil de secrets tiers, il est possible d'utiliser ce keystore en plus ou à la place du keystore intégré. Rundeck abstrait le backend du fournisseur de clés pour stocker ou récupérer efficacement les mots de passe, les clés publiques et les clés secrètes directement dans l'interface Rundeck, mais stockés dans le magasin tiers.

## Exemple Pratique : Comment utiliser un Secret pour s'authentifier auprès de nœuds distants
L'exemple lié explique comment configurer un nœud SSH distant, offrant un bon exemple pour apprendre à stocker des clés et à les référencer dans les sources de modèles pour exécuter des commandes.

## Ressources
- [Documentation Hashicorp Vault](https://www.vaultproject.io/docs)
- [Documentation Thycotic](https://docs.thycotic.com/ss/current)
- [Documentation Cyberark](https://docs.cyberark.com/pas/latest/en/home.htm)
