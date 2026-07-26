package models

type MasterEnvelope struct {
	ID             string             `json:"id" gorm:"primaryKey"`
	UserID         string             `json:"user_id" gorm:"type:uuid;index"`
	Name           string             `json:"name"`
	TotalAllocated float64            `json:"total_allocated"`
	Pockets        []Pocket           `json:"pockets,omitempty" gorm:"foreignKey:MasterID"`
	Sources        map[string]float64 `json:"sources" gorm:"-"`
}