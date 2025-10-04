# Makefile pour simplifier la gestion de l'environnement Docker de Rundeck.

# Charge les variables d'environnement depuis le fichier .env
# Cela permet de les utiliser dans les commandes `docker-compose`.
include .env
export

# --- Commandes pour Docker Compose ---

.PHONY: up
up:
	@echo "Lancement des conteneurs Rundeck et MySQL avec Docker Compose..."
	@docker-compose up -d

.PHONY: down
down:
	@echo "Arrêt des conteneurs Docker Compose..."
	@docker-compose down

.PHONY: logs
logs:
	@echo "Affichage des logs des conteneurs..."
	@docker-compose logs -f

.PHONY: ps
ps:
	@echo "Liste des conteneurs en cours d'exécution..."
	@docker-compose ps

.PHONY: restart
restart:
	@echo "Redémarrage des services..."
	@docker-compose restart

# --- Commandes pour Docker Swarm ---

.PHONY: swarm-deploy
swarm-deploy:
	@echo "Déploiement de la stack Rundeck sur Docker Swarm..."
	@docker stack deploy -c docker-swarm.yml rundeck-stack

.PHONY: swarm-rm
swarm-rm:
	@echo "Suppression de la stack Rundeck de Docker Swarm..."
	@docker stack rm rundeck-stack

.PHONY: swarm-services
swarm-services:
	@echo "Liste des services de la stack Rundeck..."
	@docker stack services rundeck-stack

# --- Commandes de nettoyage ---

.PHONY: clean
clean: down
	@echo "Nettoyage des volumes de données (ATTENTION: supprime toutes les données)..."
	@docker volume rm $(shell basename `pwd` | sed -e 's/[^a-zA-Z0-9_.-]//g')_rundeck-data || true
	@docker volume rm $(shell basename `pwd` | sed -e 's/[^a-zA-Z0-9_.-]//g')_mysql-data || true
	@echo "Suppression des répertoires de données locaux..."
	@rm -rf ${RUNDECK_DATA_DIR}
	@rm -rf ${MYSQL_DATA_DIR}

.PHONY: help
help:
	@echo "Commandes disponibles :"
	@echo "  up              - Démarre les conteneurs en arrière-plan (Docker Compose)."
	@echo "  down            - Arrête et supprime les conteneurs (Docker Compose)."
	@echo "  logs            - Affiche les logs des conteneurs."
	@echo "  ps              - Liste les conteneurs en cours."
	@echo "  restart         - Redémarre les services."
	@echo ""
	@echo "  swarm-deploy    - Déploie la stack sur Docker Swarm."
	@echo "  swarm-rm        - Supprime la stack de Docker Swarm."
	@echo "  swarm-services  - Liste les services de la stack."
	@echo ""
	@echo "  clean           - Arrête les conteneurs et supprime les volumes de données."
	@echo "  help            - Affiche ce message d'aide."
