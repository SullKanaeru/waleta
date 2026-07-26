package service

import (
	"waleta-be/internal/repository"
)

type JournalService interface {
	GetMonthlySummary(userID string, year int, month int) (map[string]interface{}, error)
	GetYearlySummary(userID string, year int) (map[string]interface{}, error)
}

type journalService struct {
	txRepo repository.TransactionRepository
}

func NewJournalService(txRepo repository.TransactionRepository) JournalService {
	return &journalService{txRepo}
}

func (s *journalService) GetMonthlySummary(userID string, year int, month int) (map[string]interface{}, error) {
	// In a real implementation, query transactions between startOfMonth and endOfMonth
	// Here we return mock structured data to match frontend
	return map[string]interface{}{
		"status":      "reviewed",
		"score":       85,
		"total_spent": 5000000,
		"recommendation": "Pengeluaran kopi agak tinggi bulan ini.",
		"distribution": map[string]interface{}{
			"Kebutuhan": 2500000,
			"Keinginan": 1500000,
			"Tabungan":  1000000,
		},
	}, nil
}

func (s *journalService) GetYearlySummary(userID string, year int) (map[string]interface{}, error) {
	// In a real implementation, query transactions for the whole year
	return map[string]interface{}{
		"status":      "reviewed",
		"total_spent": 60000000,
		"sunburst_data": []map[string]interface{}{
			{"id": "Kebutuhan", "parent": "", "value": 30000000},
			{"id": "Belanja Harian", "parent": "Kebutuhan", "value": 15000000},
			{"id": "Listrik & Air", "parent": "Kebutuhan", "value": 5000000},
			{"id": "Transportasi", "parent": "Kebutuhan", "value": 10000000},
			{"id": "Keinginan", "parent": "", "value": 15000000},
			{"id": "Kopi & Cafe", "parent": "Keinginan", "value": 10000000},
			{"id": "Langganan", "parent": "Keinginan", "value": 5000000},
			{"id": "Tabungan", "parent": "", "value": 15000000},
			{"id": "Darurat", "parent": "Tabungan", "value": 5000000},
			{"id": "Investasi", "parent": "Tabungan", "value": 10000000},
		},
	}, nil
}