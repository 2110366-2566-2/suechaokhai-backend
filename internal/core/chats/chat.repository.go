package chats

import (
	"github.com/brain-flowing-company/pprp-backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Repository interface {
	GetAllChats(*[]models.ChatsResponses, uuid.UUID) error
}

type repositoryImpl struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repositoryImpl{
		db,
	}
}

func (repo *repositoryImpl) GetAllChats(results *[]models.ChatsResponses, userId uuid.UUID) error {
	unreadQuery := repo.db.
		Select("messages.sender_id, SUM((NOT messages.read)::INT) AS unread_count").
		Table("chat_status").
		Joins("LEFT JOIN messages ON chat_status.receiver_id = messages.receiver_id AND chat_status.sender_id = messages.sender_id").
		Group("messages.sender_id").
		Where("messages.receiver_id = ? AND messages.created_at >= chat_status.last_active_at", userId)

	latestMessages := repo.db.
		Select("DISTINCT ON (messages.sender_id) sender_id, messages.CONTENT, messages.created_at").
		Table("messages").
		Order("sender_id, created_at DESC")

	return repo.db.
		Select("*").
		Table("(?) AS a", unreadQuery).
		Joins("LEFT JOIN (?) AS b ON a.sender_id = b.sender_id", latestMessages).
		Order("created_at DESC").
		Find(results).Error
}