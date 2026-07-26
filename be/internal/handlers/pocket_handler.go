package handlers

import (
	"waleta-be/internal/models"
	"waleta-be/internal/repository"

	"github.com/gofiber/fiber/v2"
)

type PocketHandler struct {
	envRepo repository.EnvelopeRepository
}

func NewPocketHandler(envRepo repository.EnvelopeRepository) *PocketHandler {
	return &PocketHandler{envRepo}
}

func (h *PocketHandler) GetPockets(c *fiber.Ctx) error {
	masterID := c.Params("masterId")
	userID := c.Locals("user_id").(string)

	pockets, err := h.envRepo.GetPocketsByMasterID(masterID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(pockets)
}

func (h *PocketHandler) CreatePocket(c *fiber.Ctx) error {
	masterID := c.Params("masterId")
	userID := c.Locals("user_id").(string)

	var pocket models.Pocket
	if err := c.BodyParser(&pocket); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	pocket.MasterID = masterID
	pocket.UserID = userID

	if err := h.envRepo.CreatePocket(&pocket); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(pocket)
}

func (h *PocketHandler) UpdatePocket(c *fiber.Ctx) error {
	pocketID := c.Params("id")
	userID := c.Locals("user_id").(string)

	existing, err := h.envRepo.GetPocketByID(pocketID, userID)
	if err != nil || existing == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Saku tidak ditemukan"})
	}

	var req models.Pocket
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	existing.Name = req.Name
	existing.Balance = req.Balance
	existing.Icon = req.Icon
	existing.Color = req.Color
	if req.StsMode != "" {
		existing.StsMode = req.StsMode
	}
	existing.StsPeriodDays = req.StsPeriodDays
	if req.StsStartDate != "" {
		existing.StsStartDate = req.StsStartDate
	}

	if err := h.envRepo.UpdatePocket(existing); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(existing)
}

func (h *PocketHandler) DeletePocket(c *fiber.Ctx) error {
	pocketID := c.Params("id")
	userID := c.Locals("user_id").(string)

	existing, err := h.envRepo.GetPocketByID(pocketID, userID)
	if err != nil || existing == nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Saku tidak ditemukan"})
	}

	if err := h.envRepo.DeletePocket(pocketID, userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Saku berhasil dihapus"})
}