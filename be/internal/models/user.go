package models

import (
	"time"
)

type User struct {
	ID           string    `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	Name         string    `json:"name"`
	Email        string    `json:"email" gorm:"unique"`
	PasswordHash string    `json:"-"` // Don't expose password in JSON
	CreatedAt    time.Time `json:"created_at"`
}