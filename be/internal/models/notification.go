package models

import (
	"time"
)

type Notification struct {
	ID        string    `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID    string    `json:"user_id" gorm:"type:uuid"`
	Type      string    `json:"type"` // 'FRUGALITY_WARNING', 'SYSTEM_INFO', 'REMINDER'
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	IsRead    bool      `json:"is_read" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at"`
}