package service

import (
	"waleta-be/internal/repository"
)

type DashboardService interface {
	GetSummary(userID string) (map[string]interface{}, error)
}

type dashboardService struct {
	accRepo repository.AccountRepository
	envRepo repository.EnvelopeRepository
}

func NewDashboardService(accRepo repository.AccountRepository, envRepo repository.EnvelopeRepository) DashboardService {
	return &dashboardService{accRepo, envRepo}
}

func (s *dashboardService) GetSummary(userID string) (map[string]interface{}, error) {
	accounts, err := s.accRepo.GetAccountsByUserID(userID)
	if err != nil {
		return nil, err
	}
	
	var totalFunds float64
	for _, acc := range accounts {
		totalFunds += acc.Balance
	}

	envelopes, err := s.envRepo.GetEnvelopes(userID)
	if err != nil {
		return nil, err
	}

	var totalAllocated float64
	var totalNegativePockets float64
	for _, env := range envelopes {
		totalAllocated += env.TotalAllocated
		for _, p := range env.Pockets {
			if p.Balance < 0 {
				totalNegativePockets -= p.Balance
			}
		}
	}

	unallocated := totalFunds - totalAllocated - totalNegativePockets
	safeToSpend := unallocated
	if safeToSpend < 0 {
		safeToSpend = 0
	}

	return map[string]interface{}{
		"total_funds":     totalFunds,
		"total_allocated": totalAllocated,
		"safe_to_spend":   safeToSpend,
		"unallocated":     unallocated,
	}, nil
}