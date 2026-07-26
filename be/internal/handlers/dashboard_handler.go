package handlers

import (
	"waleta-be/internal/service"

	"github.com/gofiber/fiber/v2"
)

type DashboardHandler struct {
	dashboardService service.DashboardService
}

func NewDashboardHandler(dashboardService service.DashboardService) *DashboardHandler {
	return &DashboardHandler{dashboardService}
}

func (h *DashboardHandler) GetSummary(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	summary, err := h.dashboardService.GetSummary(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(summary)
}