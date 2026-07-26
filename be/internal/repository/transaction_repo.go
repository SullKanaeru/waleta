package repository

import (
	"waleta-be/internal/models"

	"gorm.io/gorm"
)

type TransactionRepository interface {
	CreateTransaction(tx *models.Transaction) error
	GetTransactionsByUserID(userID string) ([]models.Transaction, error)
	GetInboxTransactions(userID string) ([]models.Transaction, error)
	GetTransactionByID(id string, userID string) (*models.Transaction, error)
	UpdateTransactionStatus(id string, status string, pocketID *string) error
	DeleteTransactions(ids []string, userID string) error
	UpdateTransactionBasic(id string, userID string, merchantName string, notes string) error
}

type transactionRepo struct {
	db *gorm.DB
}

func NewTransactionRepository(db *gorm.DB) TransactionRepository {
	return &transactionRepo{db: db}
}

func (r *transactionRepo) CreateTransaction(tx *models.Transaction) error {
	return r.db.Create(tx).Error
}

func (r *transactionRepo) GetTransactionsByUserID(userID string) ([]models.Transaction, error) {
	var txs []models.Transaction
	err := r.db.Where("user_id = ?", userID).Order("created_at desc").Find(&txs).Error
	return txs, err
}

func (r *transactionRepo) GetInboxTransactions(userID string) ([]models.Transaction, error) {
	var txs []models.Transaction
	err := r.db.Where("user_id = ? AND status = ?", userID, "PENDING").Order("created_at desc").Find(&txs).Error
	return txs, err
}

func (r *transactionRepo) GetTransactionByID(id string, userID string) (*models.Transaction, error) {
	var tx models.Transaction
	err := r.db.Where("id = ? AND user_id = ?", id, userID).First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *transactionRepo) UpdateTransactionStatus(id string, status string, pocketID *string) error {
	updates := map[string]interface{}{"status": status}
	if pocketID != nil {
		updates["pocket_id"] = *pocketID
	}
	return r.db.Model(&models.Transaction{}).Where("id = ?", id).Updates(updates).Error
}

func (r *transactionRepo) DeleteTransactions(ids []string, userID string) error {
	return r.db.Where("id IN ? AND user_id = ?", ids, userID).Delete(&models.Transaction{}).Error
}

func (r *transactionRepo) UpdateTransactionBasic(id string, userID string, merchantName string, notes string) error {
	updates := map[string]interface{}{
		"merchant_name": merchantName,
		"notes":         notes,
	}
	return r.db.Model(&models.Transaction{}).Where("id = ? AND user_id = ?", id, userID).Updates(updates).Error
}