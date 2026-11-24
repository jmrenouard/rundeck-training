# Configurer les politiques ACL et les jobs MinIO S3

Cette procédure valide les documents YAML `.aclpolicy`, configure le Key Storage puis importe un job MinIO S3.

## Prérequis

- Rundeck répond sur `http://localhost:4440`.
- Python 3 avec `PyYAML` existe sur l'hôte.
- Le client MinIO `mc` existe sur le nœud cible.

## Procédure

1. Ouvrez `aclpolicy/index.html` dans un navigateur puis générez vos règles d'accès projet.

2. Placez un séparateur `---` entre chaque document `context` et `for` dans le fichier `.aclpolicy`.

3. Validez la syntaxe YAML de tous les templates locaux avant import.

```bash
python3 -c "import yaml, pathlib; [list(yaml.safe_load_all(p.read_text())) for p in sorted(pathlib.Path('templates').rglob('*.y*ml'))]"
```

4. Copiez le fichier `.aclpolicy` validé dans `/etc/rundeck/` sur le serveur Rundeck.

5. Ouvrez **Project Settings -> Key Storage** puis enregistrez le mot de passe MinIO sous `keys/minio/secret_key`.

6. Importez `templates/rundeck/minio/transfert-s3.yml` dans **Jobs -> Upload Definition**.

## Vérification

1. Exécutez une vérification YAML sur `templates/rundeck/minio/transfert-s3.yml`.

```bash
python3 -c "import yaml, pathlib; print(yaml.safe_load(pathlib.Path('templates/rundeck/minio/transfert-s3.yml').read_text())[0]['name'])"
```

2. Exécutez le job avec un fichier test puis vérifiez l'objet dans le bucket S3.

## Retour arrière

AVERTISSEMENT : Ne stockez aucun secret S3 en clair dans un fichier `.yaml` ou un script.

Si un fichier `.aclpolicy` bloque un projet, supprimez ce fichier puis rétablissez la version précédente :

```bash
sudo rm -f /etc/rundeck/project_webapp_custom.aclpolicy
```
