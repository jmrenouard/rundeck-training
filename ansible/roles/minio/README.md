# Rôle Ansible : MinIO

Ce rôle Ansible installe et configure **MinIO**, un serveur de stockage d'objets haute performance, compatible avec l'API Amazon S3.

## Rôle dans la Stack

Dans ce projet, MinIO sert de **magasin de logs** (`logstore`) pour Rundeck. Lorsqu'un job est exécuté, ses logs sont archivés de manière centralisée et durable dans un bucket MinIO. Cela permet de conserver un historique complet des exécutions, même si les logs sont purgés de l'interface Rundeck, et facilite l'audit et le débogage.

## Actions du Rôle

1.  **Création d'un utilisateur de service** : Crée un utilisateur et un groupe (`minio-user`) pour isoler le processus MinIO.
2.  **Création des répertoires** : Prépare le répertoire de configuration (`/etc/minio`) et le répertoire de données (`/var/minio`).
3.  **Installation** : Télécharge le binaire officiel de MinIO.
4.  **Configuration du Service** : Met en place un service `systemd` (`minio.service`) pour une gestion robuste du serveur (démarrage, arrêt, redémarrage).
5.  **Démarrage du Service** : Active et démarre le service MinIO.

## Prérequis

-   Système d'exploitation basé sur Debian/Ubuntu.
-   `systemd` comme gestionnaire de services.

## Variables du Rôle

Les variables sont définies dans `defaults/main.yml` et peuvent être surchargées dans votre inventaire, `group_vars`, ou `host_vars`.

| Variable              | Description                                                                 | Défaut                |
|-----------------------|-----------------------------------------------------------------------------|-----------------------|
| `minio_user`          | L'utilisateur système pour le service MinIO.                                | `minio-user`          |
| `minio_group`         | Le groupe système pour le service MinIO.                                    | `minio-user`          |
| `minio_config_dir`    | Répertoire pour les fichiers de configuration de MinIO.                     | `/etc/minio`          |
| `minio_data_dir`      | Répertoire où les objets seront stockés.                                    | `/var/minio`          |
| `minio_listen_addr`   | Adresse et port d'écoute pour l'API S3 (utilisé par Rundeck).               | `0.0.0.0:9000`        |
| `minio_console_addr`  | Adresse et port d'écoute pour la console web d'administration.              | `0.0.0.0:9001`        |
| `minio_root_user`     | Nom d'utilisateur de l'administrateur (root) pour l'accès à la console.     | `minio`               |
| `minio_root_password` | Mot de passe de l'administrateur (root).                                    | `minio_password`      |

### Gestion des Secrets

**IMPORTANT :** Pour un environnement de production, ne stockez **jamais** les mots de passe en clair. Utilisez **Ansible Vault** pour chiffrer `minio_root_user` et `minio_root_password`.

**Exemple (`group_vars/secrets.yml` chiffré) :**
```yaml
minio_root_user: "mon_admin_minio"
minio_root_password: "UnMotDePasseTrèsComplexe"
```

## Dépendances

Aucune.

## Exemple de Playbook

Voici comment utiliser ce rôle dans un playbook.

```yaml
---
- hosts: storage_servers
  become: yes
  roles:
    - role: minio
      # Les variables sont idéalement gérées dans group_vars/all.yml
      # et les secrets dans un fichier chiffré avec Vault.
```

## Vérification Post-Installation

Une fois le rôle exécuté, vous pouvez vérifier que MinIO fonctionne correctement :

1.  **Vérifiez le statut du service :**
    ```bash
    ssh <votre_serveur> "systemctl status minio"
    ```
    Le service doit être `active (running)`.

2.  **Accédez à la console web :**
    Ouvrez votre navigateur et allez à l'adresse `http://<ip_du_serveur>:9001`. Vous devriez voir la page de connexion de MinIO. Utilisez `minio_root_user` et `minio_root_password` pour vous connecter.

## Licence

MIT

## Auteur

Jules