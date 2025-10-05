# Documentation des Templates de Jobs Rundeck pour MinIO

Ce répertoire contient des templates de jobs Rundeck au format YAML, conçus pour interagir avec un serveur de stockage d'objets MinIO (ou tout autre service compatible S3).

## Contenu

- [`transfert-s3.yml`](#job-s3---transférer-un-fichier-vers-un-bucket)

---

### Job: S3 - Transférer un fichier vers un bucket

Le template `transfert-s3.yml` définit un job Rundeck pour envoyer un fichier depuis un nœud cible vers un bucket S3.

#### Description

Ce job est utile pour automatiser les tâches de sauvegarde ou de transfert de fichiers vers un stockage objet centralisé. Il utilise le client MinIO (`mc`) pour effectuer les opérations S3.

#### Prérequis

Le client MinIO (`mc`) doit être installé et accessible dans le `PATH` de l'utilisateur `rundeck` sur le nœud où le job sera exécuté.

#### Options du Job

Le job est paramétrable via les options suivantes :

| Option                | Description                                                          | Type          | Requis | Valeur par Défaut          |
|-----------------------|----------------------------------------------------------------------|---------------|--------|----------------------------|
| `source_file`         | Chemin complet du fichier local à transférer.                        | `text`        | Oui    | -                          |
| `destination_bucket`  | Nom du bucket S3 de destination.                                     | `text`        | Oui    | -                          |
| `destination_path`    | Préfixe (dossier) de destination dans le bucket.                      | `text`        | Non    | -                          |
| `minio_host`          | URL du serveur MinIO/S3.                                             | `text`        | Oui    | `http://localhost:9000`    |
| `minio_access_key`    | Clé d'accès S3 (Access Key).                                         | `text`        | Oui    | `minio`                    |
| `minio_secret_key`    | Clé secrète S3 (Secret Key).                                         | `secure`      | Oui    | (Stocké dans Key Storage)  |

**Note de sécurité :** La clé secrète (`minio_secret_key`) est configurée comme une option sécurisée et doit être stockée dans le **Key Storage** de Rundeck pour éviter de l'exposer en clair. Le chemin de stockage par défaut est `keys/minio/secret_key`.

#### Utilisation

1.  **Importer le job** : Dans votre projet Rundeck, allez dans la section "Jobs" et cliquez sur "Upload Definition". Sélectionnez le fichier `transfert-s3.yml` et importez-le.
2.  **Configurer le Key Storage** : Allez dans "Project Settings" > "Key Storage". Ajoutez une nouvelle clé de type "Password" et collez votre clé secrète MinIO. Enregistrez-la sous le chemin `keys/minio/secret_key` (ou mettez à jour l'option du job si vous choisissez un autre chemin).
3.  **Exécuter le job** : Lancez le job en remplissant les options requises (fichier source, bucket, etc.).