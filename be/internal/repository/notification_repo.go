package repository

import (
	"waleta-be/internal/models"

	"gorm.io/gorm"
)

type NotificationRepository interface {
	CreateNotification(notif *models.Notification) error
	GetNotificationsByUserID(userID string) ([]models.Notification, error)
	MarkAsRead(id string, userID string) error
}

type notificationRepo struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepo{db: db}
}

func (r *notificationRepo) CreateNotification(notif *models.Notification) error {
	return r.db.Create(notif).Error
}

func (r *notificationRepo) GetNotificationsByUserID(userID string) ([]models.Notification, error) {
	var notifs []models.Notification
	err := r.db.Where("user_id = ?", userID).Order("created_at desc").Find(&notifs).Error
	return notifs, err
}

func (r *notificationRepo) MarkAsRead(id string, userID string) error {
	return r.db.Model(&models.Notification{}).Where("id = ? AND user_id = ?", id, userID).Update("is_read", true).Error
}