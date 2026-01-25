.PHONY: help build up down logs test clean shell status

help:
	@echo "PgBouncer Proxy Example - Makefile"
	@echo "targets:"
	@echo "  make build         - Build images"
	@echo "  make up            - Start services"
	@echo "  make down          - Stop services"
	@echo "  make test          - Run verification tests"
	@echo "  make status        - Show pool status"
	@echo "  make clean         - Reset environment"

build:
	docker compose build

up:
	docker compose up -d
	@echo "Waiting for services..."
	@sleep 10

down:
	docker compose down

clean:
	docker compose down -v
	docker rmi proxy_multiple_dbs-pgbouncer 2>/dev/null || true

test:
	@echo "Running proxy tests..."
	@docker exec pgbouncer_proxy bash /scripts/test_proxy.sh

status:
	@echo "Current Pools:"
	@docker exec -e PGPASSWORD=admin123 pgbouncer_proxy psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;"

shell:
	@docker exec -it pgbouncer_proxy bash
