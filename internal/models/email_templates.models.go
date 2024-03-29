package models

type SendingEmailRequests struct {
	Emails []string `json:"emails"`
}

type EmailType interface {
	Path() string
}

type VerificationEmails struct {
	VerificationCode string
}

func (v VerificationEmails) Path() string {
	return "internal/templates/VerificationEmail.html"
}
