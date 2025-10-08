# Rôle Ansible : Nginx

Ce rôle Ansible installe et configure **Nginx** pour agir comme un **reverse proxy** pour les services de la stack, principalement Rundeck et Keycloak.

## Rôle dans la Stack

Nginx est le point d'entrée unique pour tout le trafic HTTP/S. Il remplit plusieurs fonctions critiques :
- **Reverse Proxy** : Redirige les requêtes des utilisateurs vers les services appropriés (Rundeck ou Keycloak) qui tournent sur des ports internes.
- **Terminaison SSL/TLS** : Gère le chiffrement HTTPS, déchargeant ainsi les applications de cette tâche. Cela centralise la gestion des certificats.
- **Noms de Domaine Personnalisés** : Permet d'accéder à Rundeck et Keycloak via des noms de domaine conviviaux (ex: `rundeck.example.com`) au lieu d'adresses IP et de ports.
- **Load Balancing (potentiel)** : Bien que non implémenté par défaut, Nginx peut être étendu pour répartir la charge sur plusieurs instances de Rundeck.

## Actions du Rôle

1.  **Installation** : Installe le paquet Nginx.
2.  **Configuration** : Déploie un fichier de configuration (`rundeck.conf`) dans `/etc/nginx/sites-available/` basé sur un template Jinja2. Ce template configure les blocs `server` pour Rundeck et Keycloak.
3.  **Activation du Site** : Crée un lien symbolique de la configuration dans `/etc/nginx/sites-enabled/`.
4.  **Validation et Rechargement** : Valide la syntaxe de la configuration Nginx (`nginx -t`) avant de recharger le service pour appliquer les changements sans interruption.

## Prérequis

-   Les services backends (Rundeck, Keycloak) doivent être en cours d'exécution et accessibles depuis le serveur Nginx.
-   Les noms de domaine que vous souhaitez utiliser doivent pointer vers l'adresse IP du serveur Nginx.

## Variables du Rôle

Les variables sont définies dans `defaults/main.yml`. Surchargez-les dans `group_vars` ou `host_vars` pour votre environnement.

| Variable              | Description                                                                 | Défaut                    |
|-----------------------|-----------------------------------------------------------------------------|---------------------------|
| `nginx_listen_port`   | Port d'écoute HTTP.                                                         | `80`                      |
| `nginx_listen_port_ssl` | Port d'écoute HTTPS.                                                        | `443`                     |
| `rundeck_domain`      | Le nom de domaine pour accéder à Rundeck.                                   | `rundeck.localhost`       |
| `keycloak_domain`     | Le nom de domaine pour accéder à Keycloak.                                  | `keycloak.localhost`      |
| `rundeck_upstream_port`| Le port sur lequel l'application Rundeck écoute.                           | `4440`                    |
| `keycloak_upstream_port`| Le port sur lequel l'application Keycloak écoute.                          | `8080`                    |
| `ssl_certificate`     | Chemin vers le certificat SSL (chaîne complète).                            | `/etc/ssl/certs/nginx.crt`|
| `ssl_certificate_key` | Chemin vers la clé privée du certificat SSL.                                | `/etc/ssl/private/nginx.key`|

### Configuration SSL/TLS

Par défaut, le rôle utilise des certificats auto-signés génériques. Pour la production, vous devez fournir vos propres certificats (ex: obtenus via Let's Encrypt). Placez vos certificats sur le serveur et mettez à jour les variables `ssl_certificate` et `ssl_certificate_key`.

## Dépendances

Aucune. Cependant, il est conçu pour fonctionner de concert avec les rôles `rundeck` et `keycloak`.

## Exemple de Playbook

Voici un exemple de playbook qui déploie la stack complète, en configurant Nginx comme reverse proxy.

```yaml
# group_vars/all.yml
rundeck_domain: "rundeck.mycompany.com"
keycloak_domain: "auth.mycompany.com"
ssl_certificate: "/etc/letsencrypt/live/rundeck.mycompany.com/fullchain.pem"
ssl_certificate_key: "/etc/letsencrypt/live/rundeck.mycompany.com/privkey.pem"
```

```yaml
# site.yml
- hosts: rundeck_server
  become: yes
  roles:
    - java
    - mysql
    - rundeck
    - keycloak
    - nginx
```

## Vérification Post-Installation

1.  **Vérifiez le statut du service Nginx :**
    ```bash
    ssh <votre_serveur> "systemctl status nginx"
    ```
    Le service doit être `active (running)`.

2.  **Accédez aux applications via le navigateur :**
    -   `https://rundeck.mycompany.com` devrait afficher l'interface de Rundeck.
    -   `https://auth.mycompany.com` devrait afficher l'interface de Keycloak.
    Vérifiez que le cadenas dans la barre d'adresse indique une connexion sécurisée.