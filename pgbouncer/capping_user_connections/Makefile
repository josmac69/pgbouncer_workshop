.PHONY: help build up down logs status test clean restart shell demo

# Default target
help:
	@echo "PgBouncer Connection Capping Example - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build              - Build Docker images"
	@echo "  make up                 - Start all services"
	@echo "  make down               - Stop all services"
	@echo "  make logs               - Show logs from all services"
	@echo "  make logs-pgbouncer     - Show PgBouncer logs"
	@echo "  make logs-postgres      - Show PostgreSQL logs"
	@echo "  make status             - Show PgBouncer pool status"
	@echo "  make config             - Show PgBouncer configuration"
	@echo "  make stats              - Show PgBouncer statistics"
	@echo "  make demo               - Run complete demonstration"
	@echo "  make test-user-limit    - Test max_user_connections limit"
	@echo "  make test-db-limit      - Test max_db_connections limit"
	@echo "  make restart            - Restart all services"
	@echo "  make clean              - Stop and remove all containers and volumes"
	@echo "  make shell              - Open shell in PgBouncer container"
	@echo "  make shell-postgres     - Open shell in PostgreSQL container"
	@echo ""

# Build Docker images
build:
	@echo "Building Docker images..."
	@echo "Note: If you encounter DNS errors, use: docker build --network=host -t capping_user_connections-pgbouncer ."
	docker-compose build

# Alternative build with host network
build-host:
	@echo "Building with host network (for DNS resolution issues)..."
	docker build --network=host -t capping_user_connections-pgbouncer .

# Start all services
up:
	@echo "Starting services..."
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Services started!"
	@echo ""
	@echo "Run 'make status' to check PgBouncer status"
	@echo "Run 'make demo' to see connection limits in action"

# Stop all services
down:
	@echo "Stopping services..."
	docker-compose down

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs from PgBouncer
logs-pgbouncer:
	docker-compose logs -f pgbouncer

# Show logs from PostgreSQL
logs-postgres:
	docker-compose logs -f postgres

# Show PgBouncer pool status
status:
	@echo "PgBouncer Pool Status:"
	@docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW POOLS;"

# Show PgBouncer configuration
config:
	@echo "PgBouncer Configuration (connection limits):"
	@docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW CONFIG;" | grep -E "(max_db_connections|max_user_connections|max_client_conn|default_pool_size)"

# Show PgBouncer statistics
stats:
	@echo "PgBouncer Statistics:"
	@docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW STATS;"

# Show databases
databases:
	@echo "PgBouncer Databases:"
	@docker exec pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer -c "SHOW DATABASES;"

# Run complete demonstration
demo:
	@echo "Running complete connection capping demonstration..."
	@docker exec pgbouncer_cap bash /scripts/demo_all.sh

# Test max_user_connections limit
test-user-limit:
	@echo "Testing max_user_connections limit..."
	@docker exec pgbouncer_cap bash /scripts/test_user_limit.sh

# Test max_db_connections limit
test-db-limit:
	@echo "Testing max_db_connections limit..."
	@docker exec pgbouncer_cap bash /scripts/test_db_limit.sh

# Run all tests
test: test-user-limit test-db-limit

# Restart all services
restart: down up

# Clean everything
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker rmi capping_user_connections-pgbouncer 2>/dev/null || true
	@echo "Cleanup complete."

# Open shell in PgBouncer container
shell:
	@docker exec -it pgbouncer_cap /bin/bash

# Open shell in PostgreSQL container
shell-postgres:
	@docker exec -it pgbouncer_postgres_cap /bin/bash

# Connect to PostgreSQL directly (bypass PgBouncer)
psql-direct:
	@docker exec -it pgbouncer_postgres_cap psql -U postgres

# Connect to PgBouncer admin console
psql-admin:
	@docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U admin -d pgbouncer

# Connect as user1 to testdb1 via PgBouncer
psql-user1:
	@docker exec -it pgbouncer_cap psql -h localhost -p 6432 -U user1 -d testdb1

# Show PostgreSQL active connections
pg-connections:
	@echo "Active PostgreSQL connections:"
	@docker exec pgbouncer_postgres_cap psql -U postgres -c "SELECT datname, usename, count(*) as connections FROM pg_stat_activity WHERE datname IS NOT NULL GROUP BY datname, usename ORDER BY datname, usename;"
