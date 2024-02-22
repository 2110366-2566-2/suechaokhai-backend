package chats

import (
	"github.com/brain-flowing-company/pprp-backend/apperror"
	"github.com/brain-flowing-company/pprp-backend/internal/models"
	"github.com/brain-flowing-company/pprp-backend/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type Handler interface {
	GetAllChats(c *fiber.Ctx) error
	GetMessagesInChat(c *fiber.Ctx) error
}

type handlerImpl struct {
	service Service
}

func NewHandler(service Service) Handler {
	return &handlerImpl{
		service,
	}
}

// @router      /api/v1/chats [get]
// @summary     Get current users chat *use cookies*
// @description Get current users chat
// @tags        chats
// @produce     json
// @success     200	{object} []models.ChatsResponses
// @failure     500 {object} models.ErrorResponses
func (h *handlerImpl) GetAllChats(c *fiber.Ctx) error {
	session, ok := c.Locals("session").(models.Sessions)
	if !ok {
		session = models.Sessions{}
	}

	var chats []models.ChatsResponses
	err := h.service.GetAllChats(&chats, session.UserId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return c.JSON(chats)
}

// @router      /api/v1/chats/:recvUserId [get]
// @summary     Get messages in a chat with recvUserId *use cookies*
// @description Get messages chatting with recvUserId. Pagination is available.
// @tags        chats
// @produce     json
// @param       offset query int false "offset"
// @param       limit query int false "default 50, max 50"
// @success     200	{object} []models.Messages
// @failure     400 {object} models.ErrorResponses
// @failure     500 {object} models.ErrorResponses
func (h *handlerImpl) GetMessagesInChat(c *fiber.Ctx) error {
	session, ok := c.Locals("session").(models.Sessions)
	if !ok {
		session = models.Sessions{}
	}

	recvUserId, err := uuid.Parse(c.Params("recvUserId"))
	if err != nil {
		return utils.ResponseError(c, apperror.InvalidUserId)
	}

	offset := c.QueryInt("offset", 0)
	limit := c.QueryInt("limit", 50)

	var msgs []models.Messages
	apperr := h.service.GetMessagesInChat(&msgs, session.UserId, recvUserId, offset, limit)
	if apperr != nil {
		return utils.ResponseError(c, apperr)
	}

	return c.JSON(msgs)
}
