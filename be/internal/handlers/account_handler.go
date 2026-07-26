package handlers

import (
	"waleta-be/internal/models"
	"waleta-be/internal/repository"

	"github.com/gofiber/fiber/v2"
)

type AccountHandler struct {
	accRepo repository.AccountRepository
	txRepo  repository.TransactionRepository
	envRepo repository.EnvelopeRepository
}

func NewAccountHandler(accRepo repository.AccountRepository, txRepo repository.TransactionRepository, envRepo repository.EnvelopeRepository) *AccountHandler {
	return &AccountHandler{accRepo, txRepo, envRepo}
}

func (h *AccountHandler) GetAccounts(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	accounts, err := h.accRepo.GetAccountsByUserID(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(accounts)
}

func (h *AccountHandler) CreateAccount(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var account models.Account
	if err := c.BodyParser(&account); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if account.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Nama rekening tidak boleh kosong"})
	}

	account.UserID = userID

	if err := h.accRepo.CreateAccount(&account); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(account)
}

func (h *AccountHandler) Reconcile(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	accountID := c.Params("id")

	var req struct {
		NewBalance float64 `json:"new_balance"`
		Difference float64 `json:"difference"`
		PocketID   *string `json:"pocket_id"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	acc, err := h.accRepo.GetAccountByID(accountID, userID)
	if err != nil || acc == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Rekening tidak ditemukan"})
	}

	if err := h.accRepo.UpdateBalance(accountID, req.NewBalance); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	if req.Difference != 0 {
		txType := "INCOME"
		notes := "Koreksi Saldo"
		if req.Difference < 0 {
			txType = "EXPENSE"
		}
		absDiff := req.Difference
		if absDiff < 0 {
			absDiff = -absDiff
		}

		tx := &models.Transaction{
			UserID:          userID,
			Type:            txType,
			Amount:          absDiff,
			SourceAccountID: &accountID,
			PocketID:        req.PocketID,
			MasterID:        req.PocketID,
			Status:          "PROCESSED",
			Notes:           notes,
		}
		_ = h.txRepo.CreateTransaction(tx)
	}

	// Auto-Sweep: Find any negative pockets and reset them
	if h.envRepo != nil {
		envelopes, _ := h.envRepo.GetEnvelopes(userID)
		for _, env := range envelopes {
			for _, p := range env.Pockets {
				if p.Balance < 0 {
					absDiff := -p.Balance
					// Update pocket balance to 0
					_ = h.envRepo.UpdatePocketBalance(p.ID, p.Balance+absDiff)
					// Update envelope total allocated (takes delta)
					_ = h.envRepo.UpdateMasterAllocated(env.ID, absDiff)
				}
			}
		}
	}

	acc.Balance = req.NewBalance
	return c.JSON(acc)
}
func (h *AccountHandler) FreshStart(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	if err := h.accRepo.FreshStart(userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Semua saldo berhasil di-nol-kan."})
}
