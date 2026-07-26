package repository

import (
	"time"
	"waleta-be/internal/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type SyncRepository interface {
	MergeInitialData(userID string, data *models.SyncData) error
	GetDeltaData(userID string, since time.Time) (*models.SyncData, error)
}

type syncRepo struct {
	db *gorm.DB
}

func NewSyncRepository(db *gorm.DB) SyncRepository {
	return &syncRepo{db: db}
}

// MergeInitialData executes an atomic database transaction to merge local SQLite data into PostgreSQL
func (r *syncRepo) MergeInitialData(userID string, data *models.SyncData) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Upsert Accounts
		if len(data.Accounts) > 0 {
			for i := range data.Accounts {
				data.Accounts[i].UserID = userID
			}
			if err := tx.Clauses(clause.OnConflict{UpdateAll: true}).Create(&data.Accounts).Error; err != nil {
				return err
			}
		}

		// 2. Upsert Master Envelopes
		if len(data.MasterEnvelopes) > 0 {
			if err := tx.Clauses(clause.OnConflict{
				Columns:   []clause.Column{{Name: "id"}},
				DoUpdates: clause.AssignmentColumns([]string{"total_allocated"}),
			}).Create(&data.MasterEnvelopes).Error; err != nil {
				return err
			}
		}

		// 3. Upsert Pockets
		if len(data.Pockets) > 0 {
			for i := range data.Pockets {
				data.Pockets[i].UserID = userID
			}
			if err := tx.Clauses(clause.OnConflict{UpdateAll: true}).Create(&data.Pockets).Error; err != nil {
				return err
			}
		}

		// 4. Insert Transactions (Ignore if ID already exists to avoid duplication)
		if len(data.Transactions) > 0 {
			for i := range data.Transactions {
				data.Transactions[i].UserID = userID
			}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&data.Transactions).Error; err != nil {
				return err
			}
		}

		// 5. Upsert Sweeping Rules
		if len(data.SweepingRules) > 0 {
			for i := range data.SweepingRules {
				data.SweepingRules[i].UserID = userID
			}
			if err := tx.Clauses(clause.OnConflict{UpdateAll: true}).Create(&data.SweepingRules).Error; err != nil {
				return err
			}
		}

		return nil
	})
}

// GetDeltaData retrieves all records created or modified after a given timestamp for multi-device sync
func (r *syncRepo) GetDeltaData(userID string, since time.Time) (*models.SyncData, error) {
	var data models.SyncData

	if err := r.db.Where("user_id = ? AND created_at >= ?", userID, since).Find(&data.Accounts).Error; err != nil {
		return nil, err
	}

	if err := r.db.Find(&data.MasterEnvelopes).Error; err != nil {
		return nil, err
	}

	if err := r.db.Where("user_id = ?", userID).Find(&data.Pockets).Error; err != nil {
		return nil, err
	}

	if err := r.db.Where("user_id = ? AND created_at >= ?", userID, since).Find(&data.Transactions).Error; err != nil {
		return nil, err
	}

	if err := r.db.Where("user_id = ?", userID).Find(&data.SweepingRules).Error; err != nil {
		return nil, err
	}

	return &data, nil
}
