package handlers

import (
	"strconv"
	"waleta-be/internal/service"

	"github.com/gofiber/fiber/v2"
)

type JournalHandler struct {
	journalService service.JournalService
}

func NewJournalHandler(journalService service.JournalService) *JournalHandler {
	return &JournalHandler{journalService}
}

func (h *JournalHandler) GetMonthlySummary(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	year, _ := strconv.Atoi(c.Params("year"))
	month, _ := strconv.Atoi(c.Params("month"))

	summary, err := h.journalService.GetMonthlySummary(userID, year, month)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(summary)
}

func (h *JournalHandler) GetYearlySummary(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	year, _ := strconv.Atoi(c.Params("year"))

	summary, err := h.journalService.GetYearlySummary(userID, year)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(summary)
}