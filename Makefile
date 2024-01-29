.PHONY: docs

up:
	docker-compose -f docker-compose.dev.yaml up -d --build --no-deps

docs:
	swag init -g ./cmd/main.go -o ./docs/

test:
	go test ./internal/... -coverprofile=coverage.out

cover:
	go tool cover -html=coverage.out

migrate:
	atlas schema apply \
		--url "postgres://postgres:123456@127.0.0.1:5432/postgres_db?sslmode=disable" \
		--to "file://./migrations/schema.sql" \
		--dev-url "docker://postgres/15"