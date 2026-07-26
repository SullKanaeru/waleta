package repository

import (
	"waleta-be/internal/models"

	"gorm.io/gorm"
)

type AccountRepository interface {
	FreshStart(userID string) error
	CreateAccount(account *models.Account) error
	GetAccountsByUserID(userID string) ([]models.Account, error)
	GetAccountByID(id string, userID string) (*models.Account, error)
	UpdateBalance(id string, newBalance float64) error
}

type accountRepo struct {
	db *gorm.DB
}

func NewAccountRepository(db *gorm.DB) AccountRepository {
	return &accountRepo{db: db}
}

func (r *accountRepo) CreateAccount(account *models.Account) error {
	return r.db.Create(account).Error
}

func (r *accountRepo) GetAccountsByUserID(userID string) ([]models.Account, error) {
	var accounts []models.Account
	err := r.db.Where("user_id = ?", userID).Find(&accounts).Error
	return accounts, err
}

func (r *accountRepo) GetAccountByID(id string, userID string) (*models.Account, error) {
	var account models.Account
	err := r.db.Where("id = ? AND user_id = ?", id, userID).First(&account).Error
	if err != nil {
		return nil, err
	}
	return &account, nil
}

func (r *accountRepo) UpdateBalance(id string, newBalance float64) error {
	return r.db.Model(&models.Account{}).Where("id = ?", id).Update("balance", newBalance).Error
}
func (r *accountRepo) FreshStart(userID string) error {
	tx := r.db.Begin()

	// 1. Delete transactions belonging to the user
	if err := tx.Where("user_id = ?", userID).Delete(&models.Transaction{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 2. Delete pockets belonging to the user
	if err := tx.Where("user_id = ?", userID).Delete(&models.Pocket{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 3. Reset total_allocated of master envelopes to 0 for the user
	if err := tx.Model(&models.MasterEnvelope{}).Where("user_id = ?", userID).Update("total_allocated", 0).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 4. Delete accounts belonging to the user
	if err := tx.Where("user_id = ?", userID).Delete(&models.Account{}).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

