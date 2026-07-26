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
	
	if err := tx.Model(&models.Account{}).Where("user_id = ?", userID).Update("balance", 0).Error; err != nil {
		tx.Rollback()
		return err
	}
	
	if err := tx.Model(&models.MasterEnvelope{}).Where("1 = 1").Update("total_allocated", 0).Error; err != nil {
		tx.Rollback()
		return err
	}
	
	if err := tx.Model(&models.Pocket{}).Where("user_id = ?", userID).Update("balance", 0).Error; err != nil {
		tx.Rollback()
		return err
	}
	
	return tx.Commit().Error
}

