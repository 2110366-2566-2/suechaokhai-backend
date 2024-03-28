package payments

import (
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/checkout/session"
)

func CheckoutV2(c *fiber.Ctx, name string, price float64) error {
	stripe.Key = "sk_test_51OmWT2BayMsgzLXzrhGhYbxvTA6QtQvBwVhU2GYCNX6GFhGgVovQSapIhDKftcwpLOvqyrruOj0Tw7HfAcfJT5sd00YBwEU9aw"
	type PaymentRequest struct {
		Name  string `json:"name"`
		Price int64  `json:"price"`
	}
	var payment PaymentRequest
	payment.Name = name
	payment.Price = int64(price) * 100

	params := &stripe.CheckoutSessionParams{
		Mode: stripe.String(string(stripe.CheckoutSessionModePayment)),
		PaymentMethodTypes: []*string{
			stripe.String(string(stripe.PaymentMethodTypeCard)),
			stripe.String(string(stripe.PaymentMethodTypePromptPay)),
		},
		LineItems: []*stripe.CheckoutSessionLineItemParams{
			&stripe.CheckoutSessionLineItemParams{
				PriceData: &stripe.CheckoutSessionLineItemPriceDataParams{
					Currency: stripe.String("thb"),
					ProductData: &stripe.CheckoutSessionLineItemPriceDataProductDataParams{
						Name: stripe.String(payment.Name),
					},
					UnitAmount: stripe.Int64(payment.Price),
				},
				Quantity: stripe.Int64(1),
			},
		},
		SuccessURL: stripe.String("http://localhost:3000"),
		CancelURL:  stripe.String("http://localhost:3000"),
	}

	s, _ := session.New(params)
	fmt.Println(s.URL)

	return c.Redirect(s.URL, fiber.StatusSeeOther)
}
