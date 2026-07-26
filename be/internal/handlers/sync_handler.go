package handlers

import (
	"time"
	"waleta-be/internal/models"
	"waleta-be/internal/service"

	"github.com/gofiber/fiber/v2"
)

type SyncHandler struct {
	syncService service.SyncService
}

func NewSyncHandler(syncService service.SyncService) *SyncHandler {
	return &SyncHandler{syncService: syncService}
}

// InitialMerge handles POST /api/v1/sync/initial
func (h *SyncHandler) InitialMerge(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	var req models.InitialSyncRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Payload sinkronisasi tidak valid: " + err.Error()})
	}

	if err := h.syncService.InitialMerge(userID, &req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Gagal menggabungkan data ke cloud: " + err.Error()})
	}

	return c.JSON(fiber.Map{
		"success":        true,
		"message":        "Proses penggabungan data (The Great Data Merge) berhasil dilakukan!",
		"sync_timestamp": time.Now().UTC(),
	})
}

// GetDelta handles GET /api/v1/sync/delta?since=...
func (h *SyncHandler) GetDelta(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	sinceStr := c.Query("since")

	since := time.Time{}
	if sinceStr != "" {
		parsed, err := time.Parse(time.RFC3339, sinceStr)
		if err == nil {
			since = parsed
		}
	}

	res, err := h.syncService.GetDelta(userID, since)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(res)
}
