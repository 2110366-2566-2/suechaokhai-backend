package models

import "github.com/google/uuid"

// payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
// user_id    UUID REFERENCES users(user_id)              NOT NULL,
// price     DOUBLE PRECISION                           NOT NULL,
// IsSuccess BOOLEAN                                    NOT NULL,
// created_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
// updated_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
// deleted_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT NULL

type Payments struct {
	PaymentId uuid.UUID `json:"payment_id" gorm:"type:uuid;primaryKey;default:gen_random_uuid();not null"`
	UserId    uuid.UUID `json: "user_id"    gorm:"type:uuid;not null"`
	Price     float64   `json:"price"      gorm:"type:double precision;not null"`
	IsSuccess bool      `json:"is_success" gorm:"type:boolean;not null"`
	Name      string    `json:"name"       gorm:"type:varchar(50);not null"`
	CommonModels
}

type MyPaymentsResponse struct {
	Payments []Payments `json:"payments"`
}