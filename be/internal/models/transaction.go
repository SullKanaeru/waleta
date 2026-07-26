package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

type OCRItem struct {
	Name   string  `json:"name"`
	Amount float64 `json:"amount"`
	Qty    int     `json:"qty"`
}

type OCRItems []OCRItem

func (o OCRItems) Value() (driver.Value, error) {
	if len(o) == 0 {
		return nil, nil
	}
	return json.Marshal(o)
}

func (o *OCRItems) Scan(value interface{}) error {
	if value == nil {
		*o = OCRItems{}
		return nil
	}
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, o)
}

type Transaction struct {
	ID              string    `json:"id" gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
	UserID          string    `json:"user_id" gorm:"type:uuid"`
	Type            string    `json:"type"` // 'INCOME', 'EXPENSE', 'TRANSFER', 'CORRECTION'
	Amount          float64   `json:"amount"`
	SourceAccountID *string   `json:"source_account_id" gorm:"type:uuid"`
	PocketID        *string   `json:"pocket_id" gorm:"type:uuid"`
	MasterID        *string   `json:"master_id"`
	MerchantName    string    `json:"merchant_name"`
	Status          string    `json:"status"` // 'PENDING', 'PROCESSED'
	Notes           string    `json:"notes"`
	OCRItems        OCRItems  `json:"ocr_items" gorm:"type:jsonb"`
	CreatedAt       time.Time `json:"created_at"`
}