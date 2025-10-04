# Rôle Ansible: Nginx Reverse Proxy pour Rundeck

Ce rôle installe et configure Nginx en tant que reverse proxy pour une instance de Rundeck.

## Prérequis

Ce rôle nécessite que Rundeck soit installé et en cours d'exécution sur la machine cible. Le rôle `rundeck` doit être exécuté avant ce rôle.

## Variables du Rôle

Les variables disponibles pour ce rôle sont listées ci-dessous, avec leurs valeurs par défaut (voir `defaults/main.yml`):

| Variable | Description | Valeur par défaut |
|---|---|---|
| `nginx_listen_port` | Le port sur lequel Nginx écoutera les requêtes HTTP. | `80` |
| `rundeck_port` | Le port sur lequel l'application Rundeck est en cours d'exécution. | `4440` |

## Dépendances

Ce rôle n'a pas de dépendances directes sur d'autres rôles Galaxy. Cependant, il est conçu pour fonctionner avec le rôle `rundeck` de ce projet.

## Exemple de Playbook

Voici un exemple de la manière d'utiliser ce rôle dans un playbook Ansible :

```yaml
- hosts: serveurs
  roles:
    - role: java
    - role: mysql
    - role: rundeck
    - role: nginx
```

## Licence

MIT

## Auteur

Jules