package handlers

import (
	"time"
	"waleta-be/internal/models"
	"waleta-be/internal/repository"

	"github.com/gofiber/fiber/v2"
)

type EnvelopeHandler struct {
	envRepo repository.EnvelopeRepository
	accRepo repository.AccountRepository
	txRepo  repository.TransactionRepository
}

func NewEnvelopeHandler(
	envRepo repository.EnvelopeRepository,
	accRepo repository.AccountRepository,
	txRepo repository.TransactionRepository,
) *EnvelopeHandler {
	return &EnvelopeHandler{envRepo: envRepo, accRepo: accRepo, txRepo: txRepo}
}

func (h *EnvelopeHandler) GetEnvelopes(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	
	envelopes, err := h.envRepo.GetEnvelopes(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	for i := range envelopes {
		sources, err := h.envRepo.GetEnvelopeSources(userID, envelopes[i].ID)
		if err == nil {
			envelopes[i].Sources = sources
		} else {
			envelopes[i].Sources = make(map[string]float64)
		}

		// Check expired custom period pockets
		var activePockets []models.Pocket
		for _, p := range envelopes[i].Pockets {
			isExpired := false
			if p.StsMode == "custom_period" && p.StsPeriodDays > 0 && p.StsStartDate != "" && len(p.StsStartDate) >= 10 {
				if t, err := time.Parse("2006-01-02", p.StsStartDate[:10]); err == nil {
					if time.Since(t).Hours()/24 >= float64(p.StsPeriodDays) {
						isExpired = true
					}
				}
			}
			if isExpired {
				_ = h.envRepo.DeletePocket(p.ID, userID)
			} else {
				activePockets = append(activePockets, p)
			}
		}
		envelopes[i].Pockets = activePockets
	}
	
	return c.JSON(envelopes)
}

func (h *EnvelopeHandler) AllocateFunds(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var req struct {
		AccountID string  `json:"account_id"`
		MasterID  string  `json:"master_id"` // 'kebutuhan', 'keinginan', 'tabungan'
		PocketID  *string `json:"pocket_id"` // Optional
		Amount    float64 `json:"amount"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if req.AccountID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Rekening asal wajib dipilih"})
	}

	if req.MasterID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "MasterID (kebutuhan/keinginan/tabungan) wajib diisi"})
	}

	if req.Amount <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Nominal alokasi harus lebih dari 0"})
	}

	// 1. Check account balance & deduct
	acc, err := h.accRepo.GetAccountByID(req.AccountID, userID)
	if err != nil || acc == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Rekening tidak ditemukan"})
	}

	if acc.Balance < req.Amount {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Saldo rekening tidak mencukupi"})
	}

	// (Removed deduction of account balance since envelope allocation is virtual)

	// 2. Update Master Envelope total_allocated
	if err := h.envRepo.UpdateMasterAllocated(req.MasterID, userID, req.Amount); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	// 3. If PocketID specified, update pocket balance delta
	if req.PocketID != nil && *req.PocketID != "" {
		if err := h.envRepo.UpdatePocketBalanceDelta(*req.PocketID, req.Amount); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	// 4. Create ALLOCATION transaction record
	tx := &models.Transaction{
		UserID:          userID,
		Type:            "ALLOCATION",
		Amount:          req.Amount,
		SourceAccountID: &req.AccountID,
		MasterID:        &req.MasterID,
		PocketID:        req.PocketID,
		Status:          "PROCESSED",
		MerchantName:    "Alokasi Dana",
	}
	_ = h.txRepo.CreateTransaction(tx)

	return c.JSON(fiber.Map{
		"message": "Alokasi dana berhasil dilakukan",
		"data":    req,
	})
}