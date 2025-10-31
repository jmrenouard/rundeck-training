🔐 Guide des Connecteurs d'Authentification Rundeck

Ce document détaille les différentes méthodes d'authentification disponibles dans Rundeck, en différenciant les fonctionnalités de la version Open Source (Community) de celles de la version Entreprise (Process Automation), avec les configurations associées.

## 1. Connecteurs en Version Open Source (Rundeck Community)
La version open source de Rundeck s'appuie principalement sur le mécanisme JAAS (Java Authentication and Authorization Service).

### 📄 Le module `PropertyFileLoginModule` (par défaut)
C'est la méthode la plus simple, activée par défaut. Elle utilise un fichier plat pour stocker les utilisateurs, mots de passe et rôles.

*   **Cas d'usage :** Idéal pour les tests, les petites équipes ou lorsque vous n'avez pas d'annuaire d'utilisateurs centralisé.
*   **Fichiers de configuration :** `/etc/rundeck/realm.properties` et `/etc/rundeck/rundeck-config.properties`.

**Exemple de `realm.properties` :**
```properties
# Syntaxe: user: password,role1,role2,...
# Le mot de passe peut être en clair (non recommandé) ou chiffré (voir section 4).
admin:ADMIN,user,admin,architect
api_user:ENC[...],api_token
jean-marie:ENC[...],user,developpeur
```
Pour que Rundeck utilise ce mode, aucune configuration spécifique n'est nécessaire car c'est le comportement par défaut.

### 🏢 Le module `JettyCachingLdapLoginModule` (LDAP / Active Directory)
Le connecteur le plus courant pour intégrer Rundeck à un annuaire d'entreprise.

*   **Cas d'usage :** Centraliser l'authentification sur un annuaire LDAP ou Active Directory.
*   **Fichiers de configuration :** Un fichier JAAS dédié (ex: `/etc/rundeck/jaas-ldap.conf`) et `/etc/rundeck/rundeck-config.properties`.

**Exemple de `jaas-ldap.conf` :**
```
ldap {
    com.dtolabs.rundeck.jetty.jaas.JettyCachingLdapLoginModule required
    debug="true"
    contextFactory="com.sun.jndi.ldap.LdapCtxFactory"
    providerUrl="ldap://imporelec.local:389"
    authenticationMethod="simple"
    bindDn="cn=rundeck-svc,ou=ServiceAccounts,dc=imporelec,dc=local"
    // Le mot de passe est stocké de manière sécurisée (voir section 4)
    bindPassword="[storage-path:keys/ldap/bindPassword]"
    userBaseDn="ou=Users,dc=imporelec,dc=local"
    userRdnAttribute="sAMAccountName"
    userIdAttribute="sAMAccountName"
    userObjectClass="user"
    roleBaseDn="ou=Groups,dc=imporelec,dc=local"
    roleNameAttribute="cn"
    roleMemberAttribute="member"
    roleObjectClass="group"
    cacheDurationMillis="300000";
};
```
**Configuration de Rundeck (`/etc/rundeck/profile`) :**
```bash
# ... autres options ...
RDECK_JVM_OPTS="-Djava.security.auth.login.config=/etc/rundeck/jaas-ldap.conf -Dloginmodule.name=ldap"
# ... autres options ...
```
> **Note :** Le `loginmodule.name` (ici `ldap`) doit correspondre au nom du bloc défini dans votre fichier `jaas-ldap.conf`.

#### Mapping avancé des rôles LDAP
Pour des besoins plus complexes, vous pouvez affiner la manière dont les groupes LDAP sont mappés en rôles Rundeck.

*   **Groupes imbriqués :** Le module LDAP standard de Rundeck ne résout pas les appartenances à des groupes imbriqués nativement. Pour cela, votre annuaire (comme Active Directory) doit exposer un attribut qui contient l'ensemble des groupes d'un utilisateur, y compris les groupes hérités. L'attribut `memberOf:1.2.840.113556.1.4.1941:` est souvent utilisé pour cela.
*   **Filtres supplémentaires :** Vous pouvez utiliser `userFilter` ou `roleFilter` pour restreindre les utilisateurs ou les groupes qui peuvent s'authentifier.
    ```
    // N'autorise que les utilisateurs membres du groupe 'RundeckUsers'
    userFilter="(&(sAMAccountName={0})(memberOf=cn=RundeckUsers,ou=Groups,dc=imporelec,dc=local))"
    ```

### 🐧 Le module `JettyPamLoginModule` (PAM)
Permet une authentification via les comptes locaux du serveur hébergeant Rundeck.

*   **Cas d'usage :** Permettre aux utilisateurs système de se connecter à Rundeck avec leurs identifiants locaux.
*   **Fichiers de configuration :** `/etc/rundeck/jaas-pam.conf` et `/etc/rundeck/profile`.

**Exemple de `jaas-pam.conf` :**
```
pam {
    org.eclipse.jetty.jaas.spi.PamLoginModule required
    debug="true"
    serviceName="sshd"; // Utilise la configuration PAM du service sshd
};
```
**Configuration de Rundeck (`/etc/rundeck/profile`) :**
```bash
# ... autres options ...
RDECK_JVM_OPTS="-Djava.security.auth.login.config=/etc/rundeck/jaas-pam.conf -Dloginmodule.name=pam"
# ... autres options ...
```

## 2. Connecteurs en Version Entreprise (Process Automation)

### 🔑 Authentification unique (SSO - Single Sign-On)
La configuration du SSO (SAML ou OIDC) se fait en grande partie via l'interface graphique de Process Automation, mais elle est activée dans le fichier de configuration principal.

*   **Fournisseurs compatibles :** Okta, Azure AD, Keycloak, ADFS, etc.
*   **Configuration :** Se fait via l'interface graphique et `/etc/rundeck/rundeck-config.properties`.

**Configuration de Rundeck (`rundeck-config.properties`) :**
```properties
# Activation du module de sécurité de PagerDuty/Rundeck
rundeck.security.gui.module=pd-sso
rundeck.security.api.module=pd-sso

# Configuration spécifique au SSO
rundeck.sso.login.enabled=true
rundeck.sso.login.serviceProvider.id=urn:rundeck:sso
```
La majorité des détails (URL de l'IdP, certificats, mapping) sont ensuite gérés dans la section "SSO Configuration" de l'interface d'administration.

## 3. Contournement pour le SSO en Open Source (Mode Pré-authentifié)

Pour le mode "pre-authenticated" avec un reverse proxy, vous devez l'activer dans Rundeck.

*   **Principe :** Le reverse proxy gère l'authentification et passe l'identité de l'utilisateur à Rundeck via un en-tête HTTP.
*   **Configuration :** Se fait dans `/etc/rundeck/rundeck-config.properties`.

**Configuration de Rundeck (`rundeck-config.properties`) :**
```properties
# Activer le mode pré-authentifié
rundeck.security.authorization.preauthenticated.enabled=true
rundeck.security.authentication.preauthenticated.enabled=true

# Nom de l'en-tête HTTP qui contiendra le nom de l'utilisateur
rundeck.security.authorization.preauthenticated.userNameHeader=X-Forwarded-User

# Nom de l'en-tête HTTP qui contiendra les rôles
rundeck.security.authorization.preauthenticated.userRolesHeader=X-Forwarded-Roles

# Activer la redirection sur la page de login si l'en-tête n'est pas présent
rundeck.security.authentication.preauthenticated.redirectLogout=true
rundeck.security.authentication.preauthenticated.redirectUrl=/user/login
```

### Exemple de configuration avec Nginx en Reverse Proxy
Le reverse proxy est le composant qui authentifie l'utilisateur et transmet ensuite les informations d'identité à Rundeck.

**Exemple de configuration pour Nginx :**
```nginx
server {
    listen 80;
    server_name rundeck.monentreprise.com;

    # Activer l'authentification (exemple avec authentification basique)
    auth_basic "Accès restreint à Rundeck";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:4440; # URL de votre instance Rundeck
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # 1. Transmettre l'utilisateur authentifié
        proxy_set_header X-Forwarded-User $remote_user;

        # 2. Transmettre les rôles (ici, statiques)
        proxy_set_header X-Forwarded-Roles "user,dev";
    }
}
```
> **Avertissement de sécurité :** L'accès à votre instance Rundeck (sur le port 4440) doit être strictement contrôlé par un pare-feu pour que seul le reverse proxy puisse y accéder.

### Intégration avec Keycloak (via Reverse Proxy)
Pour la version Community, vous pouvez utiliser un reverse proxy qui gère l'authentification OIDC avec Keycloak.

1.  **Configurez un client OIDC** dans votre realm Keycloak.
2.  **Utilisez un module pour votre reverse proxy** (ex: `mod_auth_openidc` pour Apache ou `nginx-lua-oidc` pour Nginx) pour sécuriser l'URL de Rundeck.
3.  **Le module OIDC**, après une authentification réussie, injectera les informations de l'utilisateur (comme `OIDC_CLAIM_preferred_username`) dans des variables.
4.  **Configurez votre reverse proxy** pour qu'il passe ces variables dans les en-têtes `X-Forwarded-User` et `X-Forwarded-Roles`.

## 4. 🔒 Sécurisation des Mots de Passe (Chiffrement)
Il est fortement déconseillé de stocker des mots de passe en clair.

### Chiffrement pour le fichier `realm.properties`
Utilisez l'utilitaire `rundeck-storage-converter` pour chiffrer un mot de passe.

**Commande à exécuter sur le serveur Rundeck :**
```bash
java -cp /var/lib/rundeck/bootstrap/rundeck-storage-converter-*.jar \
com.rundeck.storage.converter.Converter -t password -p 'MonMotDePasseSecret' -e
```
La commande retournera une chaîne `ENC[...]` à copier dans `realm.properties`.

### Sécurisation du mot de passe LDAP (Méthode Recommandée)
La meilleure pratique est d'utiliser le Key Storage de Rundeck.

1.  **Stocker le mot de passe dans le Key Storage** via l'interface graphique ou avec `rd-cli`.
    ```bash
    # Crée une entrée de type mot de passe
    rd keys create -t password -p keys/ldap/bindPassword -f <(echo "le_mot_de_passe_du_compte_svc")
    ```
2.  **Référencer la clé dans `jaas-ldap.conf`**. Rundeck remplacera dynamiquement cette référence par le mot de passe.
    ```
    ...
    bindPassword="[storage-path:keys/ldap/bindPassword]"
    ...
    ```

## 5. 🛠️ Dépannage des Problèmes d'Authentification
*   **"Authentication failed for user" :**
    *   Vérifiez les identifiants.
    *   Activez le mode `debug="true"` dans votre fichier JAAS pour obtenir des logs détaillés dans `/var/log/rundeck/rundeck.log`.
    *   Assurez-vous que les `bindDn` et `bindPassword` pour LDAP sont corrects.
*   **Problèmes de certificat avec LDAPS :** Si vous utilisez `ldaps://`, la JVM de Rundeck doit faire confiance au certificat de votre autorité de certification. Importez le certificat CA dans le truststore de la JVM avec `keytool`.
*   **Utilisateur authentifié mais sans permissions :**
    *   Vérifiez que les rôles (`roleBaseDn`, `roleNameAttribute`, etc.) sont correctement configurés dans le fichier JAAS.
    *   Assurez-vous que les ACL policies (`.aclpolicy`) dans votre projet accordent bien des permissions aux rôles mappés.

## 6. Tableau Récapitulatif

| Connecteur / Fonctionnalité | Version Open Source | Version Entreprise | Fichier(s) de configuration clé(s) |
| :--- | :---: | :---: | :--- |
| Fichier plat (`realm.properties`) | ✅ | ✅ | `realm.properties` |
| LDAP / Active Directory | ✅ | ✅ | `jaas-ldap.conf`, `/etc/rundeck/profile` |
| PAM (Utilisateurs locaux) | ✅ | ✅ | `jaas-pam.conf`, `/etc/rundeck/profile` |
| SSO (SAML, OIDC) | ❌ | ✅ | `rundeck-config.properties` + IHM |
| SSO via Reverse Proxy | ✅ | ✅ | `rundeck-config.properties` + config du proxy |
