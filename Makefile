SHELL := /usr/bin/env bash

.PHONY: up down logs status

up:
	./scripts/up.sh

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

status:
	./scripts/status.sh
