package models

import (
	"github.com/brain-flowing-company/pprp-backend/internal/enums"
	"github.com/google/uuid"
)

type Sessions struct {
	Email          string                `json:"email,omitempty"           example:"admim@email.com"`
	UserId         uuid.UUID             `json:"user_id,omitempty"         example:"123e4567-e89b-12d3-a456-426614174000"`
	RegisteredType enums.RegisteredTypes `json:"registered_type,omitempty" example:"EMAIL / GOOGLE"`
	SessionType    enums.SessionType     `json:"session_type,omitempty"    example:"LOGIN / REGISTER"`
}
