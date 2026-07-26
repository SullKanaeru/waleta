package models

type IncomeSweepingRule struct {
	ID         string   `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID     string   `json:"user_id" gorm:"type:uuid"`
	AccountID  string   `json:"account_id" gorm:"type:uuid"`
	MasterID   string   `json:"master_id"`
	Percentage *float64 `json:"percentage"`
	FixedAmount *float64 `json:"fixed_amount"`
}

type AutoCategorizationRule struct {
	ID             string `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID         string `json:"user_id" gorm:"type:uuid"`
	MerchantKeyword string `json:"merchant_keyword"`
	TargetPocketID string `json:"target_pocket_id" gorm:"type:uuid"`
}