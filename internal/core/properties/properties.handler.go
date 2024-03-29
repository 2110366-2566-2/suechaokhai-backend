package properties

import (
	"net/http"

	"github.com/brain-flowing-company/pprp-backend/apperror"
	"github.com/brain-flowing-company/pprp-backend/internal/models"
	"github.com/brain-flowing-company/pprp-backend/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type Handler interface {
	GetPropertyById(c *fiber.Ctx) error
	GetAllProperties(c *fiber.Ctx) error
	GetMyProperties(c *fiber.Ctx) error
	CreateProperty(c *fiber.Ctx) error
	UpdatePropertyById(c *fiber.Ctx) error
	DeletePropertyById(c *fiber.Ctx) error
	AddFavoriteProperty(c *fiber.Ctx) error
	RemoveFavoriteProperty(c *fiber.Ctx) error
	GetMyFavoriteProperties(c *fiber.Ctx) error
	GetTop10Properties(c *fiber.Ctx) error
}

type handlerImpl struct {
	service Service
}

func NewHandler(service Service) Handler {
	return &handlerImpl{
		service,
	}
}

// @router      /api/v1/properties/:propertyId [get]
// @summary     Get property by propertyId
// @description Get property by its id
// @tags        property
// @produce     json
// @param	    propertyId path string true "Property id"
// @success     200	{object} models.Properties
// @failure     400 {object} models.ErrorResponses "Invalid property id"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses
func (h *handlerImpl) GetPropertyById(c *fiber.Ctx) error {
	propertyId := c.Params("propertyId")

	var userId string
	if _, ok := c.Locals("session").(models.Sessions); !ok {
		userId = "00000000-0000-0000-0000-000000000000"
	} else {
		userId = c.Locals("session").(models.Sessions).UserId.String()
	}

	property := models.Properties{}
	err := h.service.GetPropertyById(&property, propertyId, userId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return c.JSON(property)
}

// @router      /api/v1/properties [get]
// @summary     Get or search properties
// @description Get all properties or search properties by query
// @tags        property
// @produce     json
// @param       query query string false "Search query"
// @param       limit query int false "Pagination limit per page, max 50, default 20"
// @param       page  query int false "Pagination page index as 1-based index, default 1"
// @param       sort query string false "Sort in format `<json_field>:<direction>` where direction can only be `desc` or `asc`. Ex. `?sort=selling_property.price:desc`"
// @param       filter query string false "Filter in format `<json_field>[<operator>]:<value>` where operator can only be greater than or equal `gte` or less than or equal `lte`. Multiple filters can be done with `,` separating each filters. Ex. `?filter=floor_size[gte]:22,floor_size[lte]:45.5`"
// @success     200	{object} models.AllPropertiesResponses
// @failure     500 {object} models.ErrorResponses "Could not get properties"
func (h *handlerImpl) GetAllProperties(c *fiber.Ctx) error {
	query := c.Query("query")
	properties := models.AllPropertiesResponses{}

	sorted := utils.NewSortedQuery(models.Properties{})
	err := sorted.ParseQuery(c.Query("sort"))
	if err != nil {
		return utils.ResponseError(c, apperror.
			New(apperror.BadRequest).
			Describe(err.Error()))
	}

	filtered := utils.NewFilteredQuery(models.Properties{})
	err = filtered.ParseQuery(c.Query("filter"))
	if err != nil {
		return utils.ResponseError(c, apperror.
			New(apperror.BadRequest).
			Describe(err.Error()))
	}

	var userId string
	if _, ok := c.Locals("session").(models.Sessions); !ok {
		userId = "00000000-0000-0000-0000-000000000000"
	} else {
		userId = c.Locals("session").(models.Sessions).UserId.String()
	}

	limit := utils.Clamp(c.QueryInt("limit", 20), 1, 50)
	page := utils.Max(c.QueryInt("page", 1), 1)

	paginated := utils.NewPaginatedQuery(page, limit)

	apperr := h.service.GetAllProperties(&properties, query, userId, paginated, sorted, filtered)
	if apperr != nil {
		return utils.ResponseError(c, apperr)
	}

	return c.JSON(properties)
}

// @router      /api/v1/user/me/properties [get]
// @summary     Get my properties *use cookies*
// @description Get all properties owned by the current user
// @tags        property
// @produce     json
// @param       limit query int false "Pagination limit per page, max 50, default 20"
// @param       page  query int false "Pagination page index as 1-based index, default 1"
// @param       sort query string false "Sort in format `<json_field>:<direction>` where direction can only be `desc` or `asc`. Ex. `?sort=selling_property.price:desc`"
// @success     200	{object} models.MyPropertiesResponses
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     500 {object} models.ErrorResponses
func (h *handlerImpl) GetMyProperties(c *fiber.Ctx) error {
	userId := c.Locals("session").(models.Sessions).UserId.String()

	sorted := utils.NewSortedQuery(models.Properties{})
	err := sorted.ParseQuery(c.Query("sort"))
	if err != nil {
		return utils.ResponseError(c, apperror.
			New(apperror.BadRequest).
			Describe(err.Error()))
	}

	limit := utils.Clamp(c.QueryInt("limit", 20), 1, 50)
	page := utils.Max(c.QueryInt("page", 1), 1)

	paginated := utils.NewPaginatedQuery(page, limit)

	properties := models.MyPropertiesResponses{}
	apperr := h.service.GetPropertyByOwnerId(&properties, userId, paginated, sorted)
	if apperr != nil {
		return utils.ResponseError(c, apperr)
	}

	return c.JSON(properties)
}

// @router      /api/v1/properties [post]
// @summary     Create a property *user cookies*
// @description Create a property with formData *upload property images (array of images) in formData with field `property_images`. Available formats are .png / .jpg / .jpeg
// @tags        property
// @produce     json
// @param       formData formData models.PropertyInfos true "Property details"
// @success     200	{object} models.MessageResponses "Property created"
// @failure     400 {object} models.ErrorResponses "Invalid request body"
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses "Could not create property"
func (h *handlerImpl) CreateProperty(c *fiber.Ctx) error {
	property := models.PropertyInfos{
		PropertyId: uuid.New(),
	}

	if err := c.BodyParser(&property); err != nil {
		return utils.ResponseError(c, apperror.
			New(apperror.InvalidBody).
			Describe("Invalid request body"))
	}

	userId := c.Locals("session").(models.Sessions).UserId
	property.OwnerId = userId

	formFiles, _ := c.MultipartForm()
	propertyImages := formFiles.File["property_images"]

	err := h.service.CreateProperty(&property, propertyImages)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return utils.ResponseMessage(c, http.StatusOK, "Property created")
}

// @router      /api/v1/properties/:propertyId [patch]
// @summary     Update a property *user cookies*
// @description Update a property with formData *upload **NEW** property images (array of images) in formData with field `property_images`. Available formats are .png / .jpg / .jpeg *If you want to keep the old images, you need to include them in the formData with field `image_urls` as an array of strings
// @tags        property
// @produce     json
// @param	    propertyId path string true "Property id"
// @param       formData formData models.PropertyInfos true "Property details"
// @success     200	{object} models.MessageResponses "Property updated"
// @failure     400 {object} models.ErrorResponses "Invalid request body"
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses "Could not update property"
func (h *handlerImpl) UpdatePropertyById(c *fiber.Ctx) error {
	propertyIdString := c.Params("propertyId")
	propertyIdUuid, _ := uuid.Parse(propertyIdString)

	userId := c.Locals("session").(models.Sessions).UserId

	property := models.PropertyInfos{
		PropertyId: propertyIdUuid,
		OwnerId:    userId,
	}

	if err := c.BodyParser(&property); err != nil {
		return utils.ResponseError(c, apperror.InvalidBody)
	}

	formFiles, _ := c.MultipartForm()
	propertyImages := formFiles.File["property_images"]

	err := h.service.UpdatePropertyById(&property, propertyIdString, propertyImages)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return utils.ResponseMessage(c, http.StatusOK, "Property updated")
}

// @router      /api/v1/properties/:propertyId [delete]
// @summary     Delete a property *use cookies*
// @description Delete a property, owned by the current user, by its id
// @tags        property
// @produce     json
// @param	    propertyId path string true "Property id"
// @success     200	{object} models.MessageResponses "Property deleted"
// @failure     400 {object} models.ErrorResponses "Invalid request body"
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses "Could not delete property"
func (h *handlerImpl) DeletePropertyById(c *fiber.Ctx) error {
	propertyId := c.Params("propertyId")

	err := h.service.DeletePropertyById(propertyId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return utils.ResponseMessage(c, http.StatusOK, "Property deleted")
}

// @router      /api/v1/properties/favorites/:propertyId [post]
// @summary     Add property to favorites *use cookies*
// @description Add property to the current user favorites
// @tags        property
// @produce     json
// @param       propertyId path string true "Property id"
// @success     200	{object} models.MessageResponses "Property added to favorites"
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses "Could not add favorite property"
func (h *handlerImpl) AddFavoriteProperty(c *fiber.Ctx) error {
	propertyId := c.Params("propertyId")
	userId := c.Locals("session").(models.Sessions).UserId

	err := h.service.AddFavoriteProperty(propertyId, userId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return utils.ResponseMessage(c, http.StatusOK, "Property added to favorites")
}

// @router      /api/v1/properties/favorites/:propertyId [delete]
// @summary     Remove property to favorites *use cookies*
// @description Remove property to the current user favorites
// @tags        property
// @produce     json
// @param       propertyId path string true "Property id"
// @success     200	{object} models.MessageResponses "Property removed from favorites"
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     404 {object} models.ErrorResponses "Property id not found"
// @failure     500 {object} models.ErrorResponses "Could not remove favorite property"
func (h *handlerImpl) RemoveFavoriteProperty(c *fiber.Ctx) error {
	propertyId := c.Params("propertyId")
	userId := c.Locals("session").(models.Sessions).UserId

	err := h.service.RemoveFavoriteProperty(propertyId, userId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return utils.ResponseMessage(c, http.StatusOK, "Property removed from favorites")
}

// @router      /api/v1/user/me/favorites [get]
// @summary     Get my favorite properties *use cookies*
// @description Get all properties that the current user has added to favorites
// @tags        property
// @produce     json
// @param       limit query int false "Pagination limit per page, max 50, default 20"
// @param       page  query int false "Pagination page index as 1-based index, default 1"
// @param       sort query string false "Sort in format `<json_field>:<direction>` where direction can only be `desc` or `asc`. Ex. `?sort=selling_property.price:desc`"
// @success     200	{object} models.MyFavoritePropertiesResponses
// @failure	    403 {object} models.ErrorResponses "Unauthorized"
// @failure     500 {object} models.ErrorResponses "Could not get favorite properties"
func (h *handlerImpl) GetMyFavoriteProperties(c *fiber.Ctx) error {
	userId := c.Locals("session").(models.Sessions).UserId.String()

	sorted := utils.NewSortedQuery(models.Properties{})
	err := sorted.ParseQuery(c.Query("sort"))
	if err != nil {
		return utils.ResponseError(c, apperror.
			New(apperror.BadRequest).
			Describe(err.Error()))
	}

	limit := utils.Clamp(c.QueryInt("limit", 20), 1, 50)
	page := utils.Max(c.QueryInt("page", 1), 1)

	paginated := utils.NewPaginatedQuery(page, limit)

	properties := models.MyFavoritePropertiesResponses{}
	apperr := h.service.GetFavoritePropertiesByUserId(&properties, userId, paginated, sorted)
	if apperr != nil {
		return utils.ResponseError(c, apperr)
	}

	return c.JSON(properties)
}

// @router      /api/v1/top10properties [get]
// @summary     Get top 10 properties
// @description Get top 10 properties with the most favorites, sorted by the number of favorites then by the newest properties
// @tags        property
// @produce     json
// @success     200	{object} []models.Properties
// @failure     500 {object} models.ErrorResponses "Could not get top 10 properties"
func (h *handlerImpl) GetTop10Properties(c *fiber.Ctx) error {
	var userId string
	if _, ok := c.Locals("session").(models.Sessions); !ok {
		userId = "00000000-0000-0000-0000-000000000000"
	} else {
		userId = c.Locals("session").(models.Sessions).UserId.String()
	}

	properties := []models.Properties{}
	err := h.service.GetTop10Properties(&properties, userId)
	if err != nil {
		return utils.ResponseError(c, err)
	}

	return c.JSON(properties)
}
