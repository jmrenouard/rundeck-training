# Générateur de Jobs Rundeck

Ce répertoire contient un utilitaire web pour générer des templates de jobs Rundeck au format YAML.

## Description

L'outil `index.html` fournit une interface conviviale pour construire dynamiquement des définitions de jobs Rundeck. Il permet de configurer les options, les étapes du workflow, et les notifications, tout en générant un fichier YAML valide prêt à être importé dans Rundeck.

L'objectif est de simplifier la création de jobs complexes, en particulier ceux qui intègrent des étapes d'exécution Ansible.