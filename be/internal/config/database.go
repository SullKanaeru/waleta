package config

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"waleta-be/internal/models"
)

var DB *gorm.DB

func ConnectDB() {
	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	sslmode := os.Getenv("DB_SSLMODE")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		host, user, password, dbname, port, sslmode)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database. \n", err)
	}

	// Enable pgcrypto extension for gen_random_uuid() if needed
	db.Exec("CREATE EXTENSION IF NOT EXISTS pgcrypto;")

	// Auto Migrate models
	err = db.AutoMigrate(
		&models.User{},
		&models.Account{},
		&models.MasterEnvelope{},
		&models.Pocket{},
		&models.Transaction{},
		&models.Notification{},
		&models.IncomeSweepingRule{},
		&models.AutoCategorizationRule{},
	)
	if err != nil {
		log.Println("Database AutoMigrate failed:", err)
	} else {
		log.Println("Database AutoMigrate completed successfully")
	}

	log.Println("Connected to Database successfully")
	DB = db
}
