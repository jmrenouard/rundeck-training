# Rundeck Enterprise (Runbook Automation édition entreprise)

Rundeck Enterprise (Runbook Automation édition entreprise) ajoute des capacités de haute disponibilité, de sécurité avancée et de gestion à grande échelle par rapport à l’édition open source, avec support éditeur et plugins exclusifs.

### Haute disponibilité et clustering
- Mise en cluster avec base de données, stockage de logs et chargeur d’équilibrage partagés pour assurer la continuité de service et la montée en charge.
- Autotakeover de la planification: reprise automatique des jobs planifiés si un nœud de cluster devient indisponible, pilotée par un heartbeat d’instance.
- Politique d’exécution distante: possibilité de transférer l’exécution d’un job vers un autre nœud du cluster selon une politique, utile pour répartir la charge ou confiner des exécutions.

### Intégrations et stockage entreprise
- Log storage partagé: prise en charge de backends distants (ex. S3) avec lecture de logs en cours d’exécution via “checkpoint log storage” pour consulter les sorties en temps réel en cluster.
- Chiffrement des secrets et du keystore activé par défaut en Enterprise, avec options pour ajuster l’algorithme selon la politique de chiffrement Java déployée.
- Intégrations SSO d’entreprise (Okta, Ping) via OAuth/OIDC, avec bouton de connexion SSO et mappage groupes→rôles pour le RBAC centralisé.

### Sécurité et gouvernance
- RBAC fin avec outils de gestion ACL améliorés en Enterprise pour déléguer de manière sûre les opérations tout en auditant les actions.
- Prise en charge des en-têtes HTTP sécurité, SSL, et stockages sécurisés des clés/secrets adaptés aux environnements réglementés.
- Journalisation complète, historisation et audit centralisés pour les exécutions, avec possibilité d’export et de stockage distant des sorties d’exécution.

### Orchestration et productivité
- Workflows avancés avec stratégies d’orchestration, gestion d’erreurs, options et conditions, et un riche écosystème de plugins éditeur pour scheduler, guided tours et health checks côté Enterprise.
- Exécution distribuée via un système pluggable (SSH, WinRM, etc.) et transfert d’exécution inter-nœuds en cluster pour optimiser la localisation des actions.
- Tableaux de bord et visualisations améliorés pour suivre files d’attente, exécutions et santé du système, au-delà de l’interface open source standard.

### Opérations à grande échelle
- Support officiel de topologies HA derrière ELB/HAProxy/IIS, avec health checks spécifiques sur l’API d’état d’exécution pour router uniquement vers les nœuds actifs.
- Modèles de ressources partagés (fichiers, scripts, endpoints REST) pour que l’inventaire de nœuds reste cohérent sur tous les membres du cluster.
- Outils et guides de maintenance, sauvegarde, tuning et montée de version pensés pour des environnements de production multi-équipes.

### Support éditeur et accompagnement
- Abonnement Enterprise avec support standard ou 24x7, assistance au déploiement et aux bonnes pratiques d’usage en production.
- Mises à jour, correctifs et plugins exclusifs “Enterprise-only”, centrés sur la sécurité, la gestion à l’échelle et l’observabilité de la plateforme.

### Exemple de configuration HAProxy (sonde santé)
```
backend defaultservice
  cookie JSESSIONID prefix nocache
  option httpchk get /api/32/system/executions/status?authtoken=TOKENVALUE
  http-check expect status 200
  server rundeck1 192.168.0.1:4440 cookie rundeck1 check inter 2000 rise 2 fall 3
  server rundeck2 192.168.0.2:4440 cookie rundeck2 check inter 2000 rise 2 fall 3
```
- Cette configuration vérifie l’endpoint d’état d’exécution et n’envoie du trafic qu’aux nœuds “actifs”.

Souhaitez-vous un focus particulier, par exemple SSO Okta/Ping, chiffrement des secrets, ou un pas-à-pas de déploiement cluster avec ELB/HAProxy et stockage S3 des logs ?
