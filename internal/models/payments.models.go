package models

import (
	"github.com/brain-flowing-company/pprp-backend/internal/enums"
	"github.com/google/uuid"
)

// payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
// user_id    UUID REFERENCES users(user_id)              NOT NULL,
// price     DOUBLE PRECISION                           NOT NULL,
// IsSuccess BOOLEAN                                    NOT NULL,
// created_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
// updated_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
// deleted_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT NULL
type Payments struct {
	PaymentId     uuid.UUID           `json:"payment_id" `
	AgreementId   uuid.UUID           `json:"agreement_id" `
	PaymentMethod enums.PaymentMethod `json:"payment_method" `
	UserId        uuid.UUID           `json:"user_id" `
	Price         float64             `json:"price" `
	IsSuccess     bool                `json:"is_success"`
	Name          string              `json:"name"`
	CommonModels
}

type MyPaymentsResponse struct {
	Payments []Payments `json:"payments"`
}
