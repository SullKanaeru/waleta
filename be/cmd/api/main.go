package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/joho/godotenv"

	"waleta-be/internal/config"
	"waleta-be/internal/handlers"
	"waleta-be/internal/middleware"
	"waleta-be/internal/repository"
	"waleta-be/internal/service"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	// Initialize database connection
	config.ConnectDB()
	db := config.DB

	// Repositories
	authRepo := repository.NewAuthRepository(db)
	accRepo := repository.NewAccountRepository(db)
	envRepo := repository.NewEnvelopeRepository(db)
	txRepo := repository.NewTransactionRepository(db)
	ruleRepo := repository.NewRuleRepository(db)
	notifRepo := repository.NewNotificationRepository(db)
	syncRepo := repository.NewSyncRepository(db)

	// Services
	authService := service.NewAuthService(authRepo)
	txService := service.NewTransactionService(txRepo, accRepo, envRepo, ruleRepo, notifRepo)
	dashboardService := service.NewDashboardService(accRepo, envRepo)
	journalService := service.NewJournalService(txRepo)
	syncService := service.NewSyncService(syncRepo)

	// Handlers
	authHandler := handlers.NewAuthHandler(authService)
	accHandler := handlers.NewAccountHandler(accRepo, txRepo, envRepo)
	envHandler := handlers.NewEnvelopeHandler(envRepo, accRepo, txRepo)
	pocketHandler := handlers.NewPocketHandler(envRepo)
	txHandler := handlers.NewTransactionHandler(txService, txRepo)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService)
	journalHandler := handlers.NewJournalHandler(journalService)
	notifHandler := handlers.NewNotificationHandler(notifRepo)
	syncHandler := handlers.NewSyncHandler(syncService)

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		AppName: "Waleta Backend API",
	})

	// Middleware
	app.Use(logger.New())
	app.Use(recover.New())

	// Routes
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Waleta API is running",
		})
	})

	api := app.Group("/api/v1")

	// Auth (Public)
	auth := api.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)

	// Protected Routes
	protected := api.Group("", middleware.Protected())
	
	// Auth (Protected)
	protected.Get("/auth/me", authHandler.Me)

	// Accounts
	accounts := protected.Group("/accounts")
	accounts.Get("/", accHandler.GetAccounts)
	accounts.Post("/", accHandler.CreateAccount)
	accounts.Post("/fresh-start", accHandler.FreshStart)
	accounts.Post("/:id/reconcile", accHandler.Reconcile)

	// Envelopes & Pockets
	envelopes := protected.Group("/envelopes")
	envelopes.Get("/", envHandler.GetEnvelopes)
	envelopes.Post("/allocate", envHandler.AllocateFunds)
	envelopes.Get("/:masterId/pockets", pocketHandler.GetPockets)
	envelopes.Post("/:masterId/pockets", pocketHandler.CreatePocket)
	envelopes.Put("/pockets/:id", pocketHandler.UpdatePocket)
	envelopes.Delete("/pockets/:id", pocketHandler.DeletePocket)

	// Transactions
	transactions := protected.Group("/transactions")
	transactions.Get("/", txHandler.GetTransactions)
	transactions.Post("/income", txHandler.RecordIncome)
	transactions.Post("/expense", txHandler.RecordExpense)
	transactions.Post("/expense/ocr", txHandler.RecordExpense) // Can reuse or make specific
	transactions.Get("/inbox", txHandler.GetInbox)
	transactions.Post("/inbox/:id/assign", txHandler.AssignInbox)
	transactions.Delete("/", txHandler.DeleteTransactions)
	transactions.Put("/:id", txHandler.UpdateTransaction)

	// Dashboard
	dashboard := protected.Group("/dashboard")
	dashboard.Get("/summary", dashboardHandler.GetSummary)

	// Journal
	journal := protected.Group("/journal")
	journal.Get("/monthly/:year/:month", journalHandler.GetMonthlySummary)
	journal.Get("/yearly/:year", journalHandler.GetYearlySummary)

	// Notifications
	notifications := protected.Group("/notifications")
	notifications.Get("/", notifHandler.GetNotifications)
	notifications.Post("/:id/read", notifHandler.MarkAsRead)

	// Sync (The Great Data Merge & Delta Sync)
	sync := protected.Group("/sync")
	sync.Post("/initial", syncHandler.InitialMerge)
	sync.Get("/delta", syncHandler.GetDelta)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
