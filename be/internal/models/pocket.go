package models

type Pocket struct {
	ID            string  `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	MasterID      string  `json:"master_id"`
	UserID        string  `json:"user_id" gorm:"type:uuid"`
	Name          string  `json:"name"`
	Balance       float64 `json:"balance"`
	Icon          string  `json:"icon"`
	Color         string  `json:"color"`
	StsMode       string  `json:"sts_mode" gorm:"default:'daily'"`
	StsPeriodDays int     `json:"sts_period_days" gorm:"default:0"`
	StsStartDate  string  `json:"sts_start_date"`
}