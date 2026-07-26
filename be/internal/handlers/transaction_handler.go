package handlers

import (
	"waleta-be/internal/models"
	"waleta-be/internal/repository"
	"waleta-be/internal/service"

	"github.com/gofiber/fiber/v2"
)

type TransactionHandler struct {
	txService service.TransactionService
	txRepo    repository.TransactionRepository
}

func NewTransactionHandler(txService service.TransactionService, txRepo repository.TransactionRepository) *TransactionHandler {
	return &TransactionHandler{txService, txRepo}
}

func (h *TransactionHandler) RecordIncome(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var req struct {
		Amount       float64 `json:"amount"`
		AccountID    string  `json:"account_id"`
		MerchantName string  `json:"merchant_name"`
		Notes        string  `json:"notes"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	tx, err := h.txService.RecordIncome(userID, req.Amount, req.AccountID, req.MerchantName, req.Notes)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(tx)
}

func (h *TransactionHandler) RecordExpense(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var req struct {
		Amount       float64         `json:"amount"`
		AccountID    *string         `json:"account_id"`
		PocketID     *string         `json:"pocket_id"`
		MerchantName string          `json:"merchant_name"`
		Notes        string          `json:"notes"`
		OCRItems     models.OCRItems `json:"ocr_items"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	tx, err := h.txService.RecordExpense(userID, req.Amount, req.AccountID, req.PocketID, req.MerchantName, req.Notes, req.OCRItems)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(tx)
}

func (h *TransactionHandler) GetTransactions(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	
	txs, err := h.txRepo.GetTransactionsByUserID(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	
	return c.JSON(txs)
}

func (h *TransactionHandler) GetInbox(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	
	txs, err := h.txRepo.GetInboxTransactions(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	
	return c.JSON(txs)
}

func (h *TransactionHandler) AssignInbox(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	txID := c.Params("id")

	var req struct {
		PocketID       string `json:"pocket_id"`
		AutoCategorize bool   `json:"auto_categorize"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if err := h.txService.AssignInboxTransaction(txID, userID, req.PocketID, req.AutoCategorize); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.SendStatus(fiber.StatusOK)
}

func (h *TransactionHandler) DeleteTransactions(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req struct {
		IDs []string `json:"ids"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if len(req.IDs) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "No IDs provided"})
	}

	if err := h.txService.DeleteTransactions(userID, req.IDs); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.SendStatus(fiber.StatusOK)
}

func (h *TransactionHandler) UpdateTransaction(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	txID := c.Params("id")

	var req struct {
		MerchantName string `json:"merchant_name"`
		Notes        string `json:"notes"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	if err := h.txService.UpdateTransaction(userID, txID, req.MerchantName, req.Notes); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.SendStatus(fiber.StatusOK)
}