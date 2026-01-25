.PHONY: build up down logs status test test-connection test-isolation clean

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

status:
	docker compose exec pgbouncer systemctl status pgbouncer@tenant_a
	docker compose exec pgbouncer systemctl status pgbouncer@tenant_b

test: test-connection test-isolation

test-connection:
	@echo "Testing Tenant A (Port 6432)..."
	PGPASSWORD=password_a psql -h localhost -p 6432 -U user_a -d tenant_a_db -c "SELECT 'Tenant A Connection Successful' AS status;"
	@echo "Testing Tenant B (Port 6433)..."
	PGPASSWORD=password_b psql -h localhost -p 6433 -U user_b -d tenant_b_db -c "SELECT 'Tenant B Connection Successful' AS status;"

test-isolation:
	@echo "\n--- Testing Tenant Isolation (Negative Tests) ---\n"
	@echo "1. Attempting mismatched database access (Tenant A trying to access Tenant B DB on Tenant A Port)..."
	@# This should fail because tenant_b_db is not in pgbouncer_tenant_a.ini
	@if PGPASSWORD=password_a psql -h localhost -p 6432 -U user_a -d tenant_b_db -c "SELECT 1;" 2>&1 | grep -q 'FATAL\|ERROR'; then \
		echo " [PASS] Tenant A blocked from Tenant B DB (Database not allowed)"; \
	else \
		echo " [FAIL] Tenant A was able to access Tenant B DB!"; exit 1; \
	fi

	@echo "\n2. Attempting cross-tenant authentication (Tenant A User trying to login to Tenant B Port)..."
	@# This should fail because user_a is not in userlist_tenant_b.txt
	@if PGPASSWORD=password_a psql -h localhost -p 6433 -U user_a -d tenant_b_db -c "SELECT 1;" 2>&1 | grep -q 'FATAL\|ERROR'; then \
		echo " [PASS] Tenant A User blocked on Tenant B Port (Authentication failed)"; \
	else \
		echo " [FAIL] Tenant A User was able to login on Tenant B Port!"; exit 1; \
	fi

clean:
	docker compose down -v
	docker rmi tenant_isolation-pgbouncer
