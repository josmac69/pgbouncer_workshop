.PHONY: help build up down logs status test-connection test-admin clean restart

# Default target
help:
	@echo "PgBouncer Multiple Instances Example - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build           - Build Docker images"
	@echo "  make up              - Start all services"
	@echo "  make down            - Stop all services"
	@echo "  make logs            - Show logs from all services"
	@echo "  make logs-pgbouncer  - Show logs from PgBouncer container"
	@echo "  make logs-postgres   - Show logs from PostgreSQL container"
	@echo "  make status          - Show status of PgBouncer instances"
	@echo "  make test-connection - Test connection to PgBouncer"
	@echo "  make test-admin      - Test admin connection to each instance"
	@echo "  make restart         - Restart all services"
	@echo "  make clean           - Stop and remove all containers, volumes, and images"
	@echo ""

# Build Docker images
build:
	@echo "Building Docker images..."
	docker compose build

# Start all services
up:
	@echo "Starting services..."
	docker compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Services started. Use 'make status' to check PgBouncer instances."

# Stop all services
down:
	@echo "Stopping services..."
	docker compose down

# Show logs from all services
logs:
	docker compose logs -f

# Show logs from PgBouncer container
logs-pgbouncer:
	docker compose logs -f pgbouncer

# Show logs from PostgreSQL container
logs-postgres:
	docker compose logs -f postgres

# Show status of PgBouncer instances
status:
	@echo "Checking systemd status inside PgBouncer container..."
	@docker exec pgbouncer_multi systemctl status pgbouncer@50001 --no-pager || true
	@echo ""
	@docker exec pgbouncer_multi systemctl status pgbouncer@50002 --no-pager || true
	@echo ""
	@docker exec pgbouncer_multi systemctl status pgbouncer@50003 --no-pager || true
	@echo ""
	@docker exec pgbouncer_multi systemctl status pgbouncer@50004 --no-pager || true
	@echo ""
	@echo "Socket status:"
	@docker exec pgbouncer_multi systemctl status pgbouncer@50001.socket --no-pager || true

# Test connection to PgBouncer main port
test-connection:
	@echo "Testing connection to PgBouncer on main port 6432..."
	@docker exec -e PGPASSWORD=postgres pgbouncer_postgres psql -h pgbouncer_multi -p 6432 -U postgres -d testdb -c "SELECT 'Connection successful via PgBouncer' as message;" || echo "Connection failed"

# Test admin connection to each instance
test-admin:
	@echo "Testing admin connections to each PgBouncer instance..."
	@echo ""
	@echo "Instance 50001:"
	@docker exec -e PGPASSWORD=pgbouncer pgbouncer_multi psql -h localhost -p 50001 -U pgbouncer -d pgbouncer -c "SHOW POOLS;" || echo "Failed to connect to instance 50001"
	@echo ""
	@echo "Instance 50002:"
	@docker exec -e PGPASSWORD=pgbouncer pgbouncer_multi psql -h localhost -p 50002 -U pgbouncer -d pgbouncer -c "SHOW POOLS;" || echo "Failed to connect to instance 50002"
	@echo ""
	@echo "Instance 50003:"
	@docker exec -e PGPASSWORD=pgbouncer pgbouncer_multi psql -h localhost -p 50003 -U pgbouncer -d pgbouncer -c "SHOW POOLS;" || echo "Failed to connect to instance 50003"
	@echo ""
	@echo "Instance 50004:"
	@docker exec -e PGPASSWORD=pgbouncer pgbouncer_multi psql -h localhost -p 50004 -U pgbouncer -d pgbouncer -c "SHOW POOLS;" || echo "Failed to connect to instance 50004"

# Restart all services
restart: down up

# Clean everything
clean:
	@echo "Cleaning up..."
	docker compose down -v
	docker rmi pgbouncer_workshop_pgbouncer || true
	@echo "Cleanup complete."

# Show running processes inside PgBouncer container
ps:
	@echo "Processes inside PgBouncer container:"
	@docker exec pgbouncer_multi ps aux | grep -E '(pgbouncer|systemd)' || true

# Open shell in PgBouncer container
shell:
	@docker exec -it pgbouncer_multi /bin/bash

# Open shell in PostgreSQL container
shell-postgres:
	@docker exec -it pgbouncer_postgres /bin/bash
