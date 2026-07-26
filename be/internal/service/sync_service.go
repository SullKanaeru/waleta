package service

import (
	"time"
	"waleta-be/internal/models"
	"waleta-be/internal/repository"
)

type SyncService interface {
	InitialMerge(userID string, req *models.InitialSyncRequest) error
	GetDelta(userID string, since time.Time) (*models.DeltaSyncResponse, error)
}

type syncService struct {
	syncRepo repository.SyncRepository
}

func NewSyncService(syncRepo repository.SyncRepository) SyncService {
	return &syncService{syncRepo: syncRepo}
}

func (s *syncService) InitialMerge(userID string, req *models.InitialSyncRequest) error {
	return s.syncRepo.MergeInitialData(userID, &req.Data)
}

func (s *syncService) GetDelta(userID string, since time.Time) (*models.DeltaSyncResponse, error) {
	data, err := s.syncRepo.GetDeltaData(userID, since)
	if err != nil {
		return nil, err
	}
	return &models.DeltaSyncResponse{
		SyncTimestamp: time.Now().UTC(),
		Data:          *data,
	}, nil
}
