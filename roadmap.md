# Roadmap du Projet

Ce document présente une feuille de route pour les évolutions futures de ce dépôt. Les propositions sont organisées par thématique pour améliorer la clarté.

## I. Intégration et Déploiement Continus (CI/CD)

1.  **Mettre en place une pipeline CI/CD avec GitHub Actions** : Automatiser les tests et les déploiements à chaque push sur la branche `main`.
2.  **Intégrer un linter pour les scripts Bash** : Utiliser `shellcheck` pour garantir la qualité et la robustesse des scripts.
3.  **Intégrer un linter pour Ansible** : Utiliser `ansible-lint` pour valider les playbooks et les rôles.
4.  **Intégrer un linter pour les fichiers YAML et Markdown** : Assurer une syntaxe correcte et un formatage cohérent.
5.  **Construire et pousser les images Docker automatiquement** : Intégrer la construction des images Docker dans la CI/CD et les stocker dans un registre comme Docker Hub ou GitHub Container Registry.
6.  **Déployer automatiquement sur un environnement de staging** : Après chaque push sur `main`, déployer l'application sur un environnement de pré-production.

## II. Sécurité

7.  **Intégrer un scanner de vulnérabilités pour les images Docker** : Utiliser des outils comme Trivy ou Clair pour scanner les images Docker à la recherche de vulnérabilités connues.
8.  **Intégrer un scanner de secrets** : Utiliser `trufflehog` ou `gitleaks` pour empêcher la publication de secrets dans le code.
9.  **Gestion des secrets avec Ansible Vault** : Chiffrer les données sensibles (mots de passe, clés API) dans les playbooks Ansible.
10. **Mettre en place des audits de sécurité réguliers** : Planifier des revues de sécurité périodiques du code et de l'infrastructure.
11. **Renforcer la configuration de Keycloak** : Appliquer les meilleures pratiques de sécurité pour Keycloak (MFA, politiques de mot de passe robustes).

## III. Monitoring et Logging

12. **Centraliser les logs avec une stack ELK/EFK** : Mettre en place Elasticsearch, Logstash/Fluentd, et Kibana pour collecter, analyser et visualiser les logs de toutes les applications.
13. **Mettre en place un système de monitoring avec Prometheus et Grafana** : Superviser les performances des services (Rundeck, Keycloak, MySQL) et de l'infrastructure.
14. **Ajouter des alertes avec Alertmanager** : Configurer des alertes pour être notifié en cas de problème critique sur l'un des services.
15. **Créer des dashboards Grafana personnalisés** : Développer des tableaux de bord pour visualiser l'état de santé de l'application en un coup d'œil.

## IV. Améliorations de l'Infrastructure et d'Ansible

16. **Créer un rôle Ansible pour Keycloak** : Automatiser entièrement l'installation et la configuration de Keycloak.
17. **Créer un rôle Ansible pour la stack de monitoring** : Automatiser le déploiement de Prometheus, Grafana et Alertmanager.
18. **Utiliser des collections Ansible** : Organiser les rôles et les modules dans des collections pour une meilleure réutilisabilité.
19. **Mettre en place des tests d'infrastructure avec Molecule** : Tester les rôles Ansible dans un environnement isolé avant de les appliquer en production.
20. **Gérer l'infrastructure avec Terraform** : Utiliser Terraform pour provisionner les serveurs sur un cloud public (AWS, GCP, Azure) ou privé (OpenStack).

## V. Évolutions de Rundeck

21. **Développer des plugins Rundeck personnalisés** : Créer des plugins pour étendre les fonctionnalités de Rundeck et l'intégrer à d'autres outils.
22. **Intégrer Rundeck avec un gestionnaire de secrets externe** : Utiliser HashiCorp Vault ou CyberArk pour gérer les secrets utilisés par les jobs Rundeck.
23. **Créer des jobs Rundeck pour le déploiement applicatif** : Développer des workflows de déploiement pour des applications Java, Python, ou Node.js.
24. **Sauvegarde et restauration de Rundeck** : Créer des jobs pour automatiser la sauvegarde et la restauration de l'instance Rundeck (base de données et projets).

## VI. Documentation

25. **Créer un site de documentation avec MkDocs ou Docusaurus** : Générer un site web statique à partir des fichiers Markdown pour une navigation plus aisée.
26. **Traduire la documentation en anglais** : Rendre le projet accessible à une audience plus large.
27. **Documenter l'architecture globale** : Créer des diagrammes d'architecture (par exemple avec `draw.io` ou `PlantUML`) pour visualiser les interactions entre les différents composants.