# Documentation des Templates de Jobs Rundeck pour MinIO

Ce répertoire contient des templates de jobs Rundeck conçus pour interagir avec un serveur de stockage d'objets **MinIO** ou tout autre service compatible avec l'API **S3**.

## Contenu

- `transfert-s3.yml`

---

### Job : S3 - Transférer un Fichier vers un Bucket

Le template `transfert-s3.yml` définit un job Rundeck pour **envoyer un fichier** depuis un nœud cible vers un bucket S3.

#### Cas d'Usage

Ce job est un composant essentiel pour de nombreux workflows d'automatisation :
- **Sauvegardes Externalisées** : Après avoir créé une sauvegarde de base de données ou une archive de fichiers avec un autre job, utilisez celui-ci pour transférer l'archive vers un stockage objet sécurisé et distant.
- **Archivage de Logs** : Transférez des fichiers de logs applicatifs vers MinIO pour un stockage à long terme.
- **Distribution d'Artéfacts** : Poussez des artéfacts de build (ex: `.jar`, `.war`) vers un bucket S3 pour les rendre disponibles pour des jobs de déploiement.

#### Prérequis

Le client MinIO (`mc`) doit être installé sur le nœud où le job sera exécuté.

**Installation du client `mc` sur Linux :**

> **Sécurité :** Il est recommandé de vérifier l'intégrité du binaire téléchargé en comparant sa somme de contrôle SHA256 avec celle publiée par MinIO.

```bash
# Télécharger le binaire mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc

# Télécharger la somme de contrôle SHA256 officielle
wget https://dl.min.io/client/mc/release/linux-amd64/mc.sha256sum

# Vérifier l'intégrité du binaire
sha256sum -c mc.sha256sum

# Si la vérification est OK, installer mc
chmod +x mc
sudo mv mc /usr/local/bin/
Le client `mc` doit être accessible dans le `PATH` de l'utilisateur qui exécute les jobs Rundeck.

#### Options du Job

Le job est entièrement paramétrable via les options suivantes :

| Option                | Description                                                          | Type          | Requis | Valeur par Défaut          |
|-----------------------|----------------------------------------------------------------------|---------------|--------|----------------------------|
| `source_file`         | Chemin complet du fichier local à transférer.                        | `text`        | Oui    | -                          |
| `destination_bucket`  | Nom du bucket S3 de destination.                                     | `text`        | Oui    | -                          |
| `destination_path`    | (Optionnel) Préfixe ou "dossier" de destination dans le bucket.       | `text`        | Non    | -                          |
| `minio_host`          | URL du serveur MinIO/S3.                                             | `text`        | Oui    | `http://localhost:9000`    |
| `minio_access_key`    | Clé d'accès S3 (Access Key).                                         | `text`        | Oui    | `minio`                    |
| `minio_secret_key`    | Clé secrète S3 (Secret Key).                                         | `secure`      | Oui    | (Stocké dans Key Storage)  |

#### Configuration de la Sécurité

**IMPORTANT :** La clé secrète (`minio_secret_key`) est une information sensible. Ce job est pré-configuré pour la récupérer de manière sécurisée depuis le **Key Storage** de Rundeck.

- **Chemin par défaut dans le Key Storage** : `keys/minio/secret_key`
- **Action requise** : Avant d'exécuter le job, allez dans "Project Settings" > "Key Storage", créez une clé de type "Password", et enregistrez votre clé secrète MinIO à cet emplacement.

#### Exemple d'Utilisation

1.  **Importer le job** : Chargez le fichier `transfert-s3.yml` dans votre projet Rundeck.
2.  **Configurer le Key Storage** : Assurez-vous que votre clé secrète MinIO est bien stockée à l'emplacement `keys/minio/secret_key`.
3.  **Exécuter le Job** :
    - Lancez le job.
    - Dans le champ `source_file`, entrez `/backups/db_backup_2023-10-27.sql.gz`.
    - Dans le champ `destination_bucket`, entrez `rundeck-backups`.
    - Dans le champ `destination_path`, entrez `mysql/daily/`.
    - Le job exécutera une commande similaire à : `mc cp /backups/db_backup_2023-10-27.sql.gz myminio/rundeck-backups/mysql/daily/`.