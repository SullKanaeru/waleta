package models

import "time"

type SyncData struct {
	Accounts        []Account            `json:"accounts"`
	MasterEnvelopes []MasterEnvelope     `json:"master_envelopes"`
	Pockets         []Pocket             `json:"pockets"`
	Transactions    []Transaction        `json:"transactions"`
	SweepingRules   []IncomeSweepingRule `json:"sweeping_rules"`
}

type InitialSyncRequest struct {
	DeviceID      string    `json:"device_id"`
	SyncTimestamp time.Time `json:"sync_timestamp"`
	Data          SyncData  `json:"data"`
}

type DeltaSyncResponse struct {
	SyncTimestamp time.Time `json:"sync_timestamp"`
	Data          SyncData  `json:"data"`
}
