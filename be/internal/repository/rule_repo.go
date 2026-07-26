package repository

import (
	"waleta-be/internal/models"

	"gorm.io/gorm"
)

type RuleRepository interface {
	GetSweepingRules(userID string) ([]models.IncomeSweepingRule, error)
	GetCategorizationRules(userID string) ([]models.AutoCategorizationRule, error)
	CreateSweepingRule(rule *models.IncomeSweepingRule) error
	CreateCategorizationRule(rule *models.AutoCategorizationRule) error
}

type ruleRepo struct {
	db *gorm.DB
}

func NewRuleRepository(db *gorm.DB) RuleRepository {
	return &ruleRepo{db: db}
}

func (r *ruleRepo) GetSweepingRules(userID string) ([]models.IncomeSweepingRule, error) {
	var rules []models.IncomeSweepingRule
	err := r.db.Where("user_id = ?", userID).Find(&rules).Error
	return rules, err
}

func (r *ruleRepo) GetCategorizationRules(userID string) ([]models.AutoCategorizationRule, error) {
	var rules []models.AutoCategorizationRule
	err := r.db.Where("user_id = ?", userID).Find(&rules).Error
	return rules, err
}

func (r *ruleRepo) CreateSweepingRule(rule *models.IncomeSweepingRule) error {
	return r.db.Create(rule).Error
}

func (r *ruleRepo) CreateCategorizationRule(rule *models.AutoCategorizationRule) error {
	return r.db.Create(rule).Error
}