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

func (r *syncRepo) MergeInitialData(userID string, data *models.SyncData) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 0. Pre-process to map IDs for default "Dompet Tunai"
		idMap := make(map[string]string)
		var existingAccounts []models.Account
		if err := tx.Where("user_id = ?", userID).Find(&existingAccounts).Error; err == nil {
			for _, ea := range existingAccounts {
				for i := range data.Accounts {
					if data.Accounts[i].Name == ea.Name && (ea.Name == "Dompet Tunai" || ea.Name == "Cash" || ea.Name == "Saku") {
						if data.Accounts[i].ID != ea.ID {
							idMap[data.Accounts[i].ID] = ea.ID
							data.Accounts[i].ID = ea.ID
						}
					}
				}
			}
		}

		// 0b. Pre-process to map IDs for Master Envelopes
		envIdMap := make(map[string]string)
		var existingEnvelopes []models.MasterEnvelope
		if err := tx.Where("user_id = ?", userID).Find(&existingEnvelopes).Error; err == nil {
			for _, ee := range existingEnvelopes {
				for i := range data.MasterEnvelopes {
					if data.MasterEnvelopes[i].Name == ee.Name && (ee.Name == "Kebutuhan" || ee.Name == "Keinginan" || ee.Name == "Tabungan") {
						if data.MasterEnvelopes[i].ID != ee.ID {
							envIdMap[data.MasterEnvelopes[i].ID] = ee.ID
							data.MasterEnvelopes[i].ID = ee.ID
						}
					}
				}
			}
		}

		// Apply ID map to transactions
		if len(idMap) > 0 {
			for i := range data.Transactions {
				if data.Transactions[i].SourceAccountID != nil {
					if newID, ok := idMap[*data.Transactions[i].SourceAccountID]; ok {
						data.Transactions[i].SourceAccountID = &newID
					}
				}
				if data.Transactions[i].MasterID != nil {
					if newID, ok := envIdMap[*data.Transactions[i].MasterID]; ok {
						data.Transactions[i].MasterID = &newID
					}
				}
			}
		}

		// Apply envIdMap to Pockets
		if len(envIdMap) > 0 {
			for i := range data.Pockets {
				if newID, ok := envIdMap[data.Pockets[i].MasterID]; ok {
					data.Pockets[i].MasterID = newID
				}
			}
		}
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
			for i := range data.MasterEnvelopes {
				data.MasterEnvelopes[i].UserID = userID
			}
			if err := tx.Clauses(clause.OnConflict{
				Columns:   []clause.Column{{Name: "id"}},
				DoUpdates: clause.AssignmentColumns([]string{"total_allocated", "user_id"}),
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
