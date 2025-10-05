# Rôle Ansible : MinIO

Ce rôle Ansible installe et configure MinIO, un serveur de stockage d'objets haute performance compatible avec l'API Amazon S3.

## Description

Le rôle effectue les actions suivantes :
- Crée un utilisateur et un groupe système (`minio-user`) pour exécuter le service.
- Crée les répertoires nécessaires pour la configuration (`/etc/minio`) et les données (`/var/minio`).
- Télécharge le binaire officiel de MinIO depuis `dl.min.io`.
- Configure un service `systemd` pour gérer le serveur MinIO.
- Active et démarre le service `minio`.

## Prérequis

Ce rôle est conçu pour les systèmes d'exploitation basés sur Debian/Ubuntu qui utilisent `systemd`.

## Variables du Rôle

Les variables suivantes peuvent être surchargées pour personnaliser l'installation. Les valeurs par défaut se trouvent dans `defaults/main.yml`.

| Variable              | Description                                               | Défaut                |
|-----------------------|-----------------------------------------------------------|-----------------------|
| `minio_user`          | L'utilisateur pour le service MinIO.                      | `minio-user`          |
| `minio_group`         | Le groupe pour le service MinIO.                          | `minio-user`          |
| `minio_config_dir`    | Répertoire de configuration de MinIO.                     | `/etc/minio`          |
| `minio_data_dir`      | Répertoire de stockage des données de MinIO.              | `/var/minio`          |
| `minio_listen_addr`   | Adresse et port d'écoute de l'API S3.                     | `0.0.0.0:9000`        |
| `minio_console_addr`  | Adresse et port d'écoute de la console web.               | `0.0.0.0:9001`        |
| `minio_root_user`     | Nom d'utilisateur de l'administrateur (root).             | `minio`               |
| `minio_root_password` | Mot de passe de l'administrateur (root).                  | `minio_password`      |

**Note de sécurité :** Il est fortement recommandé de changer `minio_root_user` et `minio_root_password` et de les stocker de manière sécurisée en utilisant [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

## Dépendances

Aucune.

## Exemple de Playbook

Voici un exemple de playbook pour utiliser ce rôle :

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: minio
      vars:
        minio_root_user: "mon_super_admin"
        minio_root_password: "{{ mon_mot_de_passe_vaulté }}"
```

## Licence

MIT

## Auteur

Jules