DB_URL=postgres://waleta:waleta_password@127.0.0.1:5440/waleta?sslmode=disable

.PHONY: db-up db-down migrate-up migrate-down run

db-up:
	docker-compose up -d

db-down:
	docker-compose down

migrate-up:
	migrate -path db/migrations -database "$(DB_URL)" -verbose up

migrate-down:
	migrate -path db/migrations -database "$(DB_URL)" -verbose down

run:
	go run cmd/api/main.go
