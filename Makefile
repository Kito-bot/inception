# ======================
#      PATHS
# ======================
WP_DATA = /home/ychattou/data/wordpress
DB_DATA = /home/ychattou/data/mariadb

# ======================
#      DEFAULT
# ======================
all: up

# ======================
#      BUILD
# ======================
build:
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	docker-compose -f ./srcs/docker-compose.yml build

# ======================
#      UP
# ======================
up: build
	docker-compose -f ./srcs/docker-compose.yml up -d

# ======================
#      STOP/START/DOWN
# ======================
down:
	docker-compose -f ./srcs/docker-compose.yml down

stop:
	docker-compose -f ./srcs/docker-compose.yml stop

start:
	docker-compose -f ./srcs/docker-compose.yml start

# ======================
#      CLEAN
# ======================
clean:
	@docker stop $$(docker ps -qa) || true
	@docker rm $$(docker ps -qa) || true
	@docker rmi -f $$(docker images -qa) || true
	@docker volume rm $$(docker volume ls -q) || true
	@docker network rm $$(docker network ls -q) || true
	@rm -rf $(WP_DATA) || true
	@rm -rf $(DB_DATA) || true

# ======================
#        REBUILD
# ======================
re: clean up

# ======================
#      FULL CLEAN
# ======================
fclean: clean
	@docker system prune -a --volumes -f
