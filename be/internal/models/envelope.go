package models

type MasterEnvelope struct {
	ID             string             `json:"id" gorm:"primaryKey"` // 'kebutuhan', 'keinginan', 'tabungan'
	Name           string             `json:"name"`
	TotalAllocated float64            `json:"total_allocated"`
	Pockets        []Pocket           `json:"pockets,omitempty" gorm:"foreignKey:MasterID"`
	Sources        map[string]float64 `json:"sources" gorm:"-"`
}