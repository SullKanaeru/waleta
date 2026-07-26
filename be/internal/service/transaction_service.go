package service

import (
	"fmt"
	"waleta-be/internal/models"
	"waleta-be/internal/repository"
)

type TransactionService interface {
	RecordIncome(userID string, amount float64, accountID string, merchantName string, notes string) (*models.Transaction, error)
	RecordExpense(userID string, amount float64, accountID *string, pocketID *string, merchantName string, notes string, ocrItems models.OCRItems) (*models.Transaction, error)
	AssignInboxTransaction(txID string, userID string, pocketID string, autoCategorize bool) error
	DeleteTransactions(userID string, txIDs []string) error
	UpdateTransaction(userID string, txID string, merchantName string, notes string) error
}

type transactionService struct {
	txRepo      repository.TransactionRepository
	accRepo     repository.AccountRepository
	envRepo     repository.EnvelopeRepository
	ruleRepo    repository.RuleRepository
	notifRepo   repository.NotificationRepository
}

func NewTransactionService(
	txRepo repository.TransactionRepository,
	accRepo repository.AccountRepository,
	envRepo repository.EnvelopeRepository,
	ruleRepo repository.RuleRepository,
	notifRepo repository.NotificationRepository,
) TransactionService {
	return &transactionService{txRepo, accRepo, envRepo, ruleRepo, notifRepo}
}

func (s *transactionService) RecordIncome(userID string, amount float64, accountID string, merchantName string, notes string) (*models.Transaction, error) {
	// 1. Create Transaction
	tx := &models.Transaction{
		UserID:          userID,
		Type:            "INCOME",
		Amount:          amount,
		SourceAccountID: &accountID,
		MerchantName:    merchantName,
		Status:          "PROCESSED",
		Notes:           notes,
	}

	if err := s.txRepo.CreateTransaction(tx); err != nil {
		return nil, err
	}

	// 2. Update Account Balance
	acc, err := s.accRepo.GetAccountByID(accountID, userID)
	if err == nil && acc != nil {
		s.accRepo.UpdateBalance(accountID, acc.Balance+amount)
	}

	// 3. Auto-Sweeping Logic
	rules, err := s.ruleRepo.GetSweepingRules(userID)
	if err == nil && len(rules) > 0 {
		for _, rule := range rules {
			if rule.AccountID == accountID {
				var allocated float64
				if rule.Percentage != nil {
					allocated = amount * (*rule.Percentage / 100.0)
				} else if rule.FixedAmount != nil {
					allocated = *rule.FixedAmount
				}

				if allocated > 0 {
					s.envRepo.UpdateMasterAllocated(rule.MasterID, allocated)
					
					// Create sweeping allocation sub-transaction
					sweepTx := &models.Transaction{
						UserID:          userID,
						Type:            "ALLOCATION",
						Amount:          allocated,
						SourceAccountID: &accountID,
						MasterID:        &rule.MasterID,
						Status:          "PROCESSED",
						MerchantName:    "Income Sweeping",
					}
					_ = s.txRepo.CreateTransaction(sweepTx)
				}
			}
		}
	}

	return tx, nil
}

func (s *transactionService) RecordExpense(userID string, amount float64, accountID *string, pocketID *string, merchantName string, notes string, ocrItems models.OCRItems) (*models.Transaction, error) {
	status := "PROCESSED"
	if pocketID == nil {
		status = "PENDING"
		
		// Try auto categorization if pocket is nil
		catRules, _ := s.ruleRepo.GetCategorizationRules(userID)
		for _, rule := range catRules {
			if rule.MerchantKeyword == merchantName {
				pocketID = &rule.TargetPocketID
				status = "PROCESSED"
				break
			}
		}
	}

	tx := &models.Transaction{
		UserID:          userID,
		Type:            "EXPENSE",
		Amount:          amount,
		SourceAccountID: accountID,
		PocketID:        pocketID,
		MerchantName:    merchantName,
		Status:          status,
		Notes:           notes,
		OCRItems:        ocrItems,
	}

	if err := s.txRepo.CreateTransaction(tx); err != nil {
		return nil, err
	}

	if status == "PROCESSED" {
		if accountID != nil {
			acc, err := s.accRepo.GetAccountByID(*accountID, userID)
			if err == nil && acc != nil {
				s.accRepo.UpdateBalance(*accountID, acc.Balance-amount)
			}
		}
		if pocketID != nil && *pocketID != "" {
			if *pocketID == "kebutuhan" || *pocketID == "keinginan" || *pocketID == "tabungan" {
				_ = s.envRepo.UpdateMasterAllocated(*pocketID, -amount)
			} else {
				_ = s.envRepo.UpdatePocketBalanceDelta(*pocketID, -amount)
				if p, err := s.envRepo.GetPocketByID(*pocketID, userID); err == nil && p != nil {
					_ = s.envRepo.UpdateMasterAllocated(p.MasterID, -amount)
				}
			}
		}
	}

	return tx, nil
}

func (s *transactionService) AssignInboxTransaction(txID string, userID string, pocketID string, autoCategorize bool) error {
	// 1. Fetch Transaction
	tx, err := s.txRepo.GetTransactionByID(txID, userID)
	if err != nil {
		return fmt.Errorf("transaksi tidak ditemukan: %w", err)
	}

	// 2. Update Transaction Status & Pocket
	if err := s.txRepo.UpdateTransactionStatus(txID, "PROCESSED", &pocketID); err != nil {
		return err
	}

	// 3. Deduct Account Balance if account exists
	if tx.SourceAccountID != nil {
		acc, err := s.accRepo.GetAccountByID(*tx.SourceAccountID, userID)
		if err == nil && acc != nil {
			s.accRepo.UpdateBalance(*tx.SourceAccountID, acc.Balance-tx.Amount)
		}
	}

	// 4. Update Pocket Balance (Deduct from Pocket)
	s.envRepo.UpdatePocketBalanceDelta(pocketID, -tx.Amount)
	if p, err := s.envRepo.GetPocketByID(pocketID, userID); err == nil && p != nil {
		_ = s.envRepo.UpdateMasterAllocated(p.MasterID, -tx.Amount)
	}

	// 5. Add Auto-Categorization Rule if requested
	if autoCategorize && tx.MerchantName != "" {
		rule := &models.AutoCategorizationRule{
			UserID:          userID,
			MerchantKeyword: tx.MerchantName,
			TargetPocketID:  pocketID,
		}
		_ = s.ruleRepo.CreateCategorizationRule(rule)
	}

	return nil
}

func (s *transactionService) DeleteTransactions(userID string, txIDs []string) error {
	for _, id := range txIDs {
		tx, err := s.txRepo.GetTransactionByID(id, userID)
		if err != nil || tx == nil {
			continue // skip if not found
		}

		// Revert Balance
		if tx.SourceAccountID != nil {
			acc, err := s.accRepo.GetAccountByID(*tx.SourceAccountID, userID)
			if err == nil && acc != nil {
				if tx.Type == "INCOME" {
					_ = s.accRepo.UpdateBalance(*tx.SourceAccountID, acc.Balance-tx.Amount)
				} else if tx.Type == "EXPENSE" {
					_ = s.accRepo.UpdateBalance(*tx.SourceAccountID, acc.Balance+tx.Amount)
				}
			}
		}

		// Revert Pocket
		if tx.PocketID != nil && tx.Type == "EXPENSE" {
			_ = s.envRepo.UpdatePocketBalanceDelta(*tx.PocketID, tx.Amount)
			if p, err := s.envRepo.GetPocketByID(*tx.PocketID, userID); err == nil && p != nil {
				_ = s.envRepo.UpdateMasterAllocated(p.MasterID, tx.Amount)
			}
		} else if tx.MasterID != nil && tx.Type == "EXPENSE" {
			// For master envelope fallback
			_ = s.envRepo.UpdateMasterAllocated(*tx.MasterID, tx.Amount)
		}
	}

	return s.txRepo.DeleteTransactions(txIDs, userID)
}

func (s *transactionService) UpdateTransaction(userID string, txID string, merchantName string, notes string) error {
	return s.txRepo.UpdateTransactionBasic(txID, userID, merchantName, notes)
}