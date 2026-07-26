package repository

import (
	"waleta-be/internal/models"

	"gorm.io/gorm"
)

type EnvelopeRepository interface {
	GetEnvelopes(userID string) ([]models.MasterEnvelope, error)
	GetEnvelopeByID(id string) (*models.MasterEnvelope, error)
	CreatePocket(pocket *models.Pocket) error
	GetPocketByID(pocketID string, userID string) (*models.Pocket, error)
	UpdatePocket(pocket *models.Pocket) error
	DeletePocket(pocketID string, userID string) error
	GetPocketsByMasterID(masterID string, userID string) ([]models.Pocket, error)
	UpdateMasterAllocated(masterID string, delta float64) error
	UpdatePocketBalance(pocketID string, newBalance float64) error
	UpdatePocketBalanceDelta(pocketID string, delta float64) error
	GetEnvelopeSources(userID string, masterID string) (map[string]float64, error)
}

type envelopeRepo struct {
	db *gorm.DB
}

func NewEnvelopeRepository(db *gorm.DB) EnvelopeRepository {
	return &envelopeRepo{db: db}
}

func (r *envelopeRepo) GetEnvelopes(userID string) ([]models.MasterEnvelope, error) {
	var envelopes []models.MasterEnvelope
	// We might want to filter pockets by userID if there are multiple users
	err := r.db.Preload("Pockets", "user_id = ?", userID).Find(&envelopes).Error
	return envelopes, err
}

func (r *envelopeRepo) GetEnvelopeByID(id string) (*models.MasterEnvelope, error) {
	var envelope models.MasterEnvelope
	err := r.db.Where("id = ?", id).First(&envelope).Error
	if err != nil {
		return nil, err
	}
	return &envelope, nil
}

func (r *envelopeRepo) CreatePocket(pocket *models.Pocket) error {
	return r.db.Create(pocket).Error
}

func (r *envelopeRepo) GetPocketByID(pocketID string, userID string) (*models.Pocket, error) {
	var pocket models.Pocket
	err := r.db.Where("id = ? AND user_id = ?", pocketID, userID).First(&pocket).Error
	if err != nil {
		return nil, err
	}
	return &pocket, nil
}

func (r *envelopeRepo) UpdatePocket(pocket *models.Pocket) error {
	return r.db.Save(pocket).Error
}

func (r *envelopeRepo) DeletePocket(pocketID string, userID string) error {
	return r.db.Where("id = ? AND user_id = ?", pocketID, userID).Delete(&models.Pocket{}).Error
}

func (r *envelopeRepo) GetPocketsByMasterID(masterID string, userID string) ([]models.Pocket, error) {
	var pockets []models.Pocket
	err := r.db.Where("master_id = ? AND user_id = ?", masterID, userID).Find(&pockets).Error
	return pockets, err
}

func (r *envelopeRepo) UpdateMasterAllocated(masterID string, delta float64) error {
	return r.db.Model(&models.MasterEnvelope{}).Where("id = ?", masterID).
		Update("total_allocated", gorm.Expr("total_allocated + ?", delta)).Error
}

func (r *envelopeRepo) UpdatePocketBalance(pocketID string, newBalance float64) error {
	return r.db.Model(&models.Pocket{}).Where("id = ?", pocketID).Update("balance", newBalance).Error
}

func (r *envelopeRepo) UpdatePocketBalanceDelta(pocketID string, delta float64) error {
	return r.db.Model(&models.Pocket{}).Where("id = ?", pocketID).
		Update("balance", gorm.Expr("balance + ?", delta)).Error
}

func (r *envelopeRepo) GetEnvelopeSources(userID string, masterID string) (map[string]float64, error) {
	type Result struct {
		AccountName string  `gorm:"column:name"`
		Total       float64 `gorm:"column:total"`
	}
	var results []Result

	err := r.db.Table("transactions").
		Select("accounts.name as name, SUM(transactions.amount) as total").
		Joins("JOIN accounts ON transactions.source_account_id = accounts.id").
		Where("transactions.user_id = ? AND transactions.master_id = ? AND transactions.type = 'ALLOCATION'", userID, masterID).
		Group("accounts.name").
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	sources := make(map[string]float64)
	for _, res := range results {
		sources[res.AccountName] = res.Total
	}
	return sources, nil
}