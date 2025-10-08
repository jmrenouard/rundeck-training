# Roadmap du Projet

Ce document présente une feuille de route pour les évolutions futures de ce dépôt. Il est régulièrement mis à jour pour refléter les fonctionnalités terminées et les nouvelles idées.

---

## ✅ Fonctionnalités Réalisées

Cette section met en lumière les objectifs de la roadmap qui ont été atteints.

### Infrastructure et Automatisation
-   **Rôles Ansible Complets** : Des rôles Ansible robustes ont été créés pour déployer l'ensemble de la stack : **Java, MySQL, Rundeck, Nginx, Keycloak, et MinIO**.
-   **Scripts d'Installation Alternatifs** : Des scripts Bash complets pour l'installation, la sauvegarde et la restauration de la stack sur Ubuntu sont disponibles comme alternative à Ansible.
-   **Environnement Docker** : Un environnement `docker-compose` est fourni pour un démarrage rapide et isolé de Rundeck et MySQL, idéal pour le développement.

### Utilitaires et Outils
-   **Générateur d'ACL (`aclpolicy`)** : Un outil web pour créer et gérer les politiques de contrôle d'accès de Rundeck.
-   **Générateur de Ressources (`ressources`)** : Un outil web pour créer et gérer les fichiers de modèle de ressources (nœuds).
-   **Générateur de Jobs (`jobs`)** : Un nouvel outil web pour construire des définitions de jobs, y compris des étapes d'exécution Ansible.
-   **Bibliothèque de 40+ Templates de Jobs** : Une collection riche de templates de jobs pour Linux, Windows, et des intégrations de services (MinIO).

### Documentation et Internationalisation
-   **Documentation Complète et Enrichie** : Tous les composants du projet (Ansible, Docker, scripts, templates, utilitaires) ont une documentation `README.md` détaillée.
-   **Internationalisation (i18n)** : Les utilitaires web (`aclpolicy`, `ressources`, `jobs`) supportent le **Français** et l'**Anglais**.

---

## I. Intégration Continue et Qualité du Code (CI/CD)

1.  **Mettre en place une pipeline CI/CD avec GitHub Actions** : Automatiser les tests et les validations à chaque push.
2.  **Intégrer des Linters** :
    -   `shellcheck` pour les scripts Bash.
    -   `ansible-lint` pour les playbooks et les rôles.
    -   `yamllint` et `markdownlint` pour la cohérence des fichiers de configuration et de la documentation.
3.  **Intégrer un Scanner de Secrets** : Utiliser `trufflehog` ou `gitleaks` pour empêcher la publication accidentelle de secrets.
4.  **Tester les Rôles Ansible avec Molecule** : Mettre en place des tests d'infrastructure pour valider le comportement des rôles Ansible dans un environnement isolé.

## II. Sécurité

5.  **Intégrer un Scanner de Vulnérabilités pour Docker** : Utiliser `Trivy` ou `Clair` pour scanner les images Docker.
6.  **Renforcer la Configuration de Keycloak** : Appliquer les meilleures pratiques de sécurité (MFA, politiques de mot de passe robustes).
7.  **Intégrer Rundeck avec un Gestionnaire de Secrets Externe** : Utiliser HashiCorp Vault pour gérer les secrets des jobs Rundeck.

## III. Monitoring et Logging

8.  **Centraliser les Logs avec une Stack ELK/Loki** : Mettre en place une solution de centralisation des logs pour tous les composants.
9.  **Mettre en place un Système de Monitoring avec Prometheus & Grafana** :
    -   Créer un rôle Ansible pour déployer la stack de monitoring.
    -   Développer des dashboards Grafana personnalisés pour superviser la santé de Rundeck, Keycloak, et des serveurs.
10. **Ajouter des Alertes avec Alertmanager** : Configurer des alertes pour être notifié en cas de problème critique.

## IV. Évolutions de l'Infrastructure

11. **Gérer l'Infrastructure avec Terraform** : Utiliser Terraform pour provisionner les serveurs sur un cloud public (AWS, GCP, Azure) ou privé.
12. **Utiliser des Collections Ansible** : Organiser les rôles et modules dans des collections pour une meilleure réutilisabilité et distribution.
13. **Développer des Plugins Rundeck Personnalisés** : Créer des plugins pour étendre les fonctionnalités de Rundeck.

## V. Documentation

14. **Créer un Site de Documentation avec MkDocs** : Générer un site web statique à partir des fichiers Markdown pour une navigation plus aisée.
15. **Documenter l'Architecture Globale** : Créer des diagrammes d'architecture (avec `PlantUML` ou `draw.io`) pour visualiser les interactions entre les composants.
16. **Traduire l'ensemble de la documentation en Anglais**.