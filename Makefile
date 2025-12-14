# Makefile simple pour déploiement Docker portable
.PHONY: deploy clean test-portability

# Commande principale : build + déploiement
deploy:
	@echo "🚀 Déploiement portable avec Docker"
	@docker build -f Dockerfile.simple -t portail-deploy . 
	@docker run --rm -it \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $$(pwd):/workspace \
		-v portail-azure-credentials:/root/.azure \
		portail-deploy

# Nettoyage complet
clean:
	@echo "🧹 Nettoyage complet..."
	@docker rmi portail-deploy 2>/dev/null || true
	@docker volume rm portail-azure-credentials 2>/dev/null || true
	@docker system prune -f

# Test de portabilité : nettoie tout puis redéploie
test-portability: clean
	@echo "🧪 TEST DE PORTABILITÉ COMPLÈTE"
	@echo "================================"
	@echo "Suppression de toutes les images et volumes..."
	@echo ""
	@echo "🚀 Rebuild depuis zéro et déploiement..."
	@make deploy