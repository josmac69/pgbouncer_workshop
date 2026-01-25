.PHONY: help build up down logs life-test clean

help:
	@echo "PgBouncer Multi-Port Example"
	@echo "targets:"
	@echo "  make build         - Build images"
	@echo "  make up            - Start services"
	@echo "  make life-test     - Run multi-port traffic visualization"
	@echo "  make clean         - Reset environment"

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v
	docker rmi multi_port-pgbouncer 2>/dev/null || true

life-test:
	@echo "Setting up environment..."
	@python3 -m venv venv
	@./venv/bin/pip install -r requirements.txt > /dev/null
	@echo "Starting life test..."
	@./venv/bin/python3 life_test.py
