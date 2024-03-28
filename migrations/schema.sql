CREATE TYPE bank_names AS ENUM('KBANK', 'BBL', 'KTB', 'BAY', 'CIMB', 'TTB', 'SCB', 'GSB');

CREATE TYPE registered_types AS ENUM('EMAIL', 'GOOGLE');

CREATE TYPE agreement_types AS ENUM('SELLING', 'RENTING');

CREATE TYPE appointment_status AS ENUM('PENDING', 'CONFIRMED', 'REJECTED', 'CANCELLED', 'ARCHIVED');

CREATE TYPE agreement_status AS ENUM('AWAITING_DEPOSIT', 'AWAITING_PAYMENT', 'RENTING', 'CANCELLED', 'OVERDUE', 'ARCHIVED');

CREATE TYPE card_colors AS ENUM('LIGHT_BLUE', 'BLUE', 'DARK_BLUE', 'VERY_DARK_BLUE');

CREATE TYPE property_types AS ENUM('CONDOMINIUM', 'APARTMENT', 'SEMI_DETACHED_HOUSE', 'HOUSE', 'SERVICED_APARTMENT', 'TOWNHOUSE');

CREATE TYPE furnishing AS ENUM('UNFURNISHED', 'PARTIALLY_FURNISHED', 'FULLY_FURNISHED', 'READY_TO_MOVE_IN');

CREATE TYPE floor_size_units AS ENUM('SQM', 'SQFT');

CREATE TYPE payment_methods AS ENUM('CREDIT_CARD', 'PromptPay');

CREATE TABLE email_verification_codes
(
    email                     VARCHAR(50) PRIMARY KEY           NOT NULL,
    code                      VARCHAR(99)                       NOT NULL,
    expired_at                TIMESTAMP(0) WITH TIME ZONE       NOT NULL
);

CREATE TABLE google_oauth_states
(
    code       UUID PRIMARY KEY            NOT NULL,
    expired_at TIMESTAMP(0) WITH TIME ZONE NOT NULL
);

CREATE TABLE users
(
    user_id                             UUID PRIMARY KEY                DEFAULT gen_random_uuid(),
    registered_type                     registered_types                NOT NULL,
    email                               VARCHAR(50)                     NOT NULL,
    password                            VARCHAR(64)                     DEFAULT NULL,
    first_name                          VARCHAR(50)                     NOT NULL,
    last_name                           VARCHAR(50)                     NOT NULL,
    phone_number                        VARCHAR(10)                     NOT NULL,
    profile_image_url                   VARCHAR(2000)                   DEFAULT NULL,
    is_verified                         BOOLEAN                         DEFAULT FALSE,
    created_at                          TIMESTAMP(0) WITH TIME ZONE     DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMP(0) WITH TIME ZONE     DEFAULT CURRENT_TIMESTAMP,
    deleted_at                          TIMESTAMP(0) WITH TIME ZONE     DEFAULT NULL,
    UNIQUE(email, deleted_at),
    UNIQUE(phone_number, deleted_at)
);

CREATE TABLE user_financial_informations
(
    user_id                             UUID PRIMARY KEY REFERENCES users(user_id)  ON DELETE CASCADE   NOT NULL,
    bank_name                           bank_names                                  DEFAULT NULL,
    bank_account_number                 VARCHAR(10)                                 DEFAULT NULL,
    created_at                          TIMESTAMP(0) WITH TIME ZONE                 DEFAULT CURRENT_TIMESTAMP,
    updated_at                          TIMESTAMP(0) WITH TIME ZONE                 DEFAULT CURRENT_TIMESTAMP,
    deleted_at                          TIMESTAMP(0) WITH TIME ZONE                 DEFAULT NULL
);

CREATE TABLE credit_cards
(
    user_id                             UUID REFERENCES users (user_id) ON DELETE CASCADE,
    tag_number                          INTEGER CHECK(1 <= tag_number AND tag_number <= 4) NOT NULL,
    card_nickname                       VARCHAR(50)                     NOT NULL,
    cardholder_name                     VARCHAR(50)                     NOT NULL,
    card_number                         VARCHAR(16)                     NOT NULL,
    expire_month                        VARCHAR(2)                      NOT NULL,
    expire_year                         VARCHAR(4)                      NOT NULL,
    cvv                                 VARCHAR(3)                      NOT NULL,
    card_color                          card_colors                     DEFAULT 'LIGHT_BLUE',
    PRIMARY KEY (user_id, tag_number)
);

CREATE TABLE user_verifications 
(
    user_id                 UUID PRIMARY KEY NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    citizen_id              VARCHAR(13)      NOT NULL,
    citizen_card_image_url  VARCHAR(2000)    NOT NULL,
    verified_at             TIMESTAMP(0) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE properties
(
    property_id              UUID PRIMARY KEY UNIQUE                                DEFAULT gen_random_uuid(),
    owner_id                 UUID REFERENCES users (user_id) ON DELETE CASCADE      NOT NULL,
    property_name            VARCHAR(50)                                            NOT NULL,
    property_description     TEXT                                                   NOT NULL,
    property_type            property_types                                         NOT NULL,
    address                  VARCHAR(50)                                            NOT NULL,
    alley                    VARCHAR(50)                                            DEFAULT NULL,
    street                   VARCHAR(50)                                            NOT NULL,
    sub_district             VARCHAR(50)                                            NOT NULL,
    district                 VARCHAR(50)                                            NOT NULL,
    province                 VARCHAR(50)                                            NOT NULL,
    country                  VARCHAR(50)                                            NOT NULL,
    postal_code              CHAR(5)                                                NOT NULL,
    bedrooms                 INTEGER                                                NOT NULL,
    bathrooms                INTEGER                                                NOT NULL,
    furnishing               furnishing                                             NOT NULL,
    floor                    INTEGER                                                NOT NULL,
    floor_size               DOUBLE PRECISION                                       NOT NULL,
    floor_size_unit          floor_size_units                                       DEFAULT 'SQM',
    unit_number              INTEGER                                                NOT NULL,
    created_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT CURRENT_TIMESTAMP,
    deleted_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT NULL
);

CREATE TABLE property_images
(
    property_id UUID     REFERENCES properties (property_id) ON DELETE CASCADE      NOT NULL,
    image_url            VARCHAR(2000)                                              NOT NULL,
    created_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT CURRENT_TIMESTAMP,
    deleted_at               TIMESTAMP(0) WITH TIME ZONE                            DEFAULT NULL,
    PRIMARY KEY (property_id, image_url)
);

CREATE TABLE selling_properties
(
    property_id UUID REFERENCES properties (property_id) ON DELETE CASCADE          NOT NULL,
    price       DOUBLE PRECISION                                                        NOT NULL,
    is_sold     BOOLEAN                                                                 NOT NULL,
    created_at               TIMESTAMP(0) WITH TIME ZONE                                DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP(0) WITH TIME ZONE                                DEFAULT CURRENT_TIMESTAMP,
    deleted_at               TIMESTAMP(0) WITH TIME ZONE                                DEFAULT NULL
);

CREATE TABLE renting_properties
(
    property_id     UUID REFERENCES properties (property_id) ON DELETE CASCADE          NOT NULL,
    price_per_month DOUBLE PRECISION                                                        NOT NULL,
    is_occupied     BOOLEAN                                                                 NOT NULL,
    created_at               TIMESTAMP(0) WITH TIME ZONE                                    DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP(0) WITH TIME ZONE                                    DEFAULT CURRENT_TIMESTAMP,
    deleted_at               TIMESTAMP(0) WITH TIME ZONE                                    DEFAULT NULL
);

CREATE TABLE favorite_properties
(
    user_id         UUID REFERENCES users (user_id)             ON DELETE CASCADE   NOT NULL,
    property_id     UUID REFERENCES properties (property_id)    ON DELETE CASCADE   NOT NULL,
    PRIMARY KEY (user_id, property_id)
);

CREATE TABLE appointments
(
    appointment_id      UUID PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    property_id         UUID REFERENCES properties (property_id)   ON DELETE CASCADE    NOT NULL,
    owner_user_id       UUID REFERENCES users (user_id)            ON DELETE CASCADE    NOT NULL,
    dweller_user_id     UUID REFERENCES users (user_id)            ON DELETE CASCADE    NOT NULL,
    appointment_date    TIMESTAMP(0) WITH TIME ZONE                NOT NULL,
    status              appointment_status DEFAULT 'PENDING'       NOT NULL,
    note                TEXT                                       DEFAULT NULL,
    cancelled_message   TEXT                                       DEFAULT NULL,
    created_at          TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP(0) WITH TIME ZONE                DEFAULT NULL,
    UNIQUE (property_id, appointment_date, deleted_at)
);

CREATE TABLE agreements
(
    agreement_id        UUID PRIMARY KEY DEFAULT gen_random_uuid()          NOT NULL,
    agreement_type      agreement_types                                     NOT NULL,
    property_id         UUID REFERENCES properties (property_id)            ON DELETE CASCADE   NOT NULL,
    owner_user_id       UUID REFERENCES users (user_id)                     ON DELETE CASCADE   NOT NULL,
    dweller_user_id     UUID REFERENCES users (user_id)                     ON DELETE CASCADE   NOT NULL,
    agreement_date      TIMESTAMP(0) WITH TIME ZONE                         NOT NULL,
    status              agreement_status DEFAULT 'AWAITING_DEPOSIT'       NOT NULL,
    deposit_amount      DOUBLE PRECISION                                    DEFAULT NULL,
    payment_per_month   DOUBLE PRECISION                                    DEFAULT NULL,
    payment_duration    INTEGER                                             DEFAULT NULL,
    total_payment       DOUBLE PRECISION                                    DEFAULT NULL,
    cancelled_message   TEXT                                                DEFAULT NULL,
    created_at          TIMESTAMP(0) WITH TIME ZONE                         DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP(0) WITH TIME ZONE                         DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP(0) WITH TIME ZONE                         DEFAULT NULL,
    UNIQUE (property_id, agreement_date)
);

CREATE TABLE messages (
    message_id  UUID PRIMARY KEY         NOT NULL,
    sender_id   UUID                     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id UUID                     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content     VARCHAR(4096)            NOT NULL,
    read_at     TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    sent_at     TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE payments(
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    agreement_id UUID REFERENCES agreements(agreement_id) NOT NULL,
    payment_method payment_methods NOT NULL,
    user_id    UUID REFERENCES users(user_id)              NOT NULL, 
    price     DOUBLE PRECISION                           NOT NULL,
    IsSuccess BOOLEAN                                    NOT NULL, 
    Name       VARCHAR(50)                               NOT NULL,
    created_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP, 
    updated_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT CURRENT_TIMESTAMP, 
    deleted_at TIMESTAMP(0) WITH TIME ZONE                DEFAULT NULL
);

-------------------- RULES --------------------

CREATE RULE soft_deletion AS ON DELETE TO users DO INSTEAD (
    UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = old.user_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO user_financial_informations DO INSTEAD (
    UPDATE user_financial_informations SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = old.user_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO properties DO INSTEAD (
    UPDATE properties SET deleted_at = CURRENT_TIMESTAMP WHERE property_id = old.property_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO property_images DO INSTEAD (
    UPDATE property_images SET deleted_at = CURRENT_TIMESTAMP WHERE property_id = old.property_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO selling_properties DO INSTEAD (
    UPDATE selling_properties SET deleted_at = CURRENT_TIMESTAMP WHERE property_id = old.property_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO renting_properties DO INSTEAD (
    UPDATE renting_properties SET deleted_at = CURRENT_TIMESTAMP WHERE property_id = old.property_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO appointments DO INSTEAD (
    UPDATE appointments SET deleted_at = CURRENT_TIMESTAMP WHERE appointment_id = old.appointment_id and deleted_at IS NULL
);

CREATE RULE soft_deletion AS ON DELETE TO agreements DO INSTEAD (
    UPDATE agreements SET deleted_at = CURRENT_TIMESTAMP WHERE agreement_id = old.agreement_id and deleted_at IS NULL
);

CREATE RULE delete_users AS ON UPDATE TO users
    WHERE old.deleted_at IS NULL AND new.deleted_at IS NOT NULL
    DO ALSO (
        UPDATE properties SET deleted_at = new.deleted_at WHERE owner_id = old.user_id;
        UPDATE appointments SET deleted_at = new.deleted_at WHERE owner_user_id = old.user_id OR dweller_user_id = old.user_id;
        DELETE FROM favorite_properties WHERE user_id = old.user_id;
        DELETE FROM user_verifications WHERE user_id = old.user_id;
        UPDATE user_financial_informations SET deleted_at = new.deleted_at WHERE user_id = old.user_id;
    );

CREATE RULE delete_properties AS ON UPDATE TO properties
    WHERE old.deleted_at IS NULL AND new.deleted_at IS NOT NULL
    DO ALSO (
        DELETE FROM property_images WHERE property_id = old.property_id;
        UPDATE selling_properties SET deleted_at = new.deleted_at WHERE property_id = old.property_id;
        UPDATE renting_properties SET deleted_at = new.deleted_at WHERE property_id = old.property_id;
        DELETE FROM favorite_properties WHERE property_id = old.property_id;
        UPDATE appointments SET deleted_at = new.deleted_at WHERE property_id = old.property_id;
    );

CREATE RULE create_email_verification_codes AS ON INSERT TO email_verification_codes
    WHERE new.email = (SELECT email FROM email_verification_codes WHERE email = new.email) DO INSTEAD(
        UPDATE email_verification_codes SET code = new.code, expired_at = new.expired_at WHERE email = new.email
    );

CREATE RULE creat_user_financial_informations AS ON INSERT TO users DO ALSO (
    INSERT INTO user_financial_informations (user_id) VALUES (new.user_id)
);

CREATE RULE update_user_verified AS ON INSERT TO user_verifications DO ALSO (
    UPDATE users SET is_verified = TRUE WHERE user_id = new.user_id
);

-------------------- DUMMY DATA --------------------

INSERT INTO users (user_id, registered_type, email, password, first_name, last_name, phone_number, profile_image_url, is_verified) VALUES
('f38f80b3-f326-4825-9afc-ebc331626555', 'EMAIL', 'johnd@email.com', '$2a$10$eEkTbe/JskFiociJ8U/bGOwwiea9dZ6sN7ac9ZvuiUgtrekZ7b.ya', 'John', 'Doe', '1234567890', 'https://picsum.photos/200/300?random=1', TRUE),
('bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'EMAIL', 'sams@email.com', '$2a$10$eEkTbe/JskFiociJ8U/bGOwwiea9dZ6sN7ac9ZvuiUgtrekZ7b.ya', 'Sam', 'Smith', '0987654321', NULL, FALSE),
('a4ec4cd6-03f5-4f1c-b13d-7123d9b03617', 'EMAIL', 'markl@email.com', '$2a$10$eEkTbe/JskFiociJ8U/bGOwwiea9dZ6sN7ac9ZvuiUgtrekZ7b.ya', 'Mark', 'Lee', '0000000000', NULL, TRUE),
('62dd40da-f326-4825-9afc-2d68e06e0282', 'GOOGLE', 'cc@gmail.com', NULL, 'C', 'C', '3333333333', 'https://picsum.photos/200/300?random=1', TRUE);

INSERT INTO properties (property_id, owner_id, property_name, property_description, property_type, address, alley, street, sub_district, district, province, country, postal_code, bedrooms, bathrooms, furnishing, floor, floor_size, floor_size_unit, unit_number) VALUES
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 'f38f80b3-f326-4825-9afc-ebc331626555', 'Et sequi dolor praes', 'sdfasdfdsalflvasdldk', 'HOUSE', 'Quas iusto expedita ', 'Delisa', 'Grace', 'Michael', 'Christine', 'Anthony', 'Andrew', '53086', 3, 2, 'UNFURNISHED', 20, 45.78, 'SQM', 1123),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'f38f80b3-f326-4825-9afc-ebc331626555', 'Impedit quae itaque ', 'asludfowyegfubhsalas', 'APARTMENT', 'Sunt fuga quo perspi', 'Raquel', 'Brandy', 'Jacob', 'Lino', 'Edward', 'Reginald', '12894', 2, 1, 'FULLY_FURNISHED',18, 22.13, 'SQM', 1233),
('2dd819db-6b5f-4c29-b173-0f0bf04769fb', 'f38f80b3-f326-4825-9afc-ebc331626555', 'Architecto iure labo', 'asdasfhsfjdkaasdfjks', 'CONDOMINIUM', 'Pariatur temporibus ', 'Robert', 'Nancy', 'Barbara', 'David', 'Henry', 'David', '24264', 3, 2, 'READY_TO_MOVE_IN', 1, 200.00, 'SQFT', 555),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 'a4ec4cd6-03f5-4f1c-b13d-7123d9b03617', 'Optio in asperiores ', 'ioquwerewqpurwpqeruu', 'SEMI_DETACHED_HOUSE', 'Ea nobis mollitia ea', 'Tina', 'Linda', 'Ronald', 'Julia', 'Russell', 'William', '10287', 9, 9, 'FULLY_FURNISHED', 9, 90.99, 'SQM', 9909),
('7faf0793-3937-47f3-aa97-76ed81134c70', 'a4ec4cd6-03f5-4f1c-b13d-7123d9b03617', 'Sunt at totam animi ', 'iuwuerhihdfsiladfjas', 'TOWNHOUSE', 'Unde natus nesciunt ', 'Norma', 'Gregory', 'Donovan', 'Charles', 'Kevin', 'Tyrone', '10055', 1, 1, 'PARTIALLY_FURNISHED', 30, 90.99, 'SQFT', 1234),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'a4ec4cd6-03f5-4f1c-b13d-7123d9b03617', 'Animi vero ipsa nihi', 'hubgqewhbflasdhbfahs', 'HOUSE', 'Totam nam minus veni', 'Allen', 'Linda', 'Bobby', 'Nora', 'James', 'Lucinda', '01229', 7, 2, 'UNFURNISHED', 12, 127.27, 'SQFT', 1207),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', '62dd40da-f326-4825-9afc-2d68e06e0282', 'Numquam sit dicta be', 'euyqrbdfhaivbhdbewjf', 'SERVICED_APARTMENT', 'Consequatur incidunt', 'Cecil', 'David', 'Nancy', 'Brandon', 'John', 'Lillian', '48668', 3, 2, 'FULLY_FURNISHED', 6, 66.00, 'SQFT', 6666),
('b68f14db-fac6-4b5c-8bb3-68a2ce7efbe9', '62dd40da-f326-4825-9afc-2d68e06e0282', 'Iure nostrum ab reru', 'ewurblhdsfhladlhfdas', 'SEMI_DETACHED_HOUSE', 'Nisi officia nemo au', 'Keith', 'Joseph', 'Joseph', 'Goldie', 'Danika', 'Bernice', '47550', 1, 1, 'READY_TO_MOVE_IN', 4, 44.44, 'SQM', 4444),
('e3f29fb7-f830-43de-91ab-c67fd0c170a3', '62dd40da-f326-4825-9afc-2d68e06e0282', 'Aut nemo incidunt ul', 'sldlfghewrvjdsbppppp', 'CONDOMINIUM', 'Porro molestias rati', 'Brian', 'Gregory', 'Geraldine', 'Edward', 'Charles', 'James', '97186', 3, 1, 'UNFURNISHED', 13, 1313.13, 'SQFT', 1313);

INSERT INTO property_images (property_id, image_url) VALUES
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/0bd03187-91ac-457d-957c-3ba2f6c0d24b-1.jpeg'),
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/0bd03187-91ac-457d-957c-3ba2f6c0d24b-2.jpeg'),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/21b492b6-8d4f-45a6-af25-2fa9c1eb2042-1.jpeg'),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/21b492b6-8d4f-45a6-af25-2fa9c1eb2042-2.jpeg'),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/21b492b6-8d4f-45a6-af25-2fa9c1eb2042-3.jpeg'),
('2dd819db-6b5f-4c29-b173-0f0bf04769fb', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/2dd819db-6b5f-4c29-b173-0f0bf04769fb-1.jpeg'),
('2dd819db-6b5f-4c29-b173-0f0bf04769fb', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/2dd819db-6b5f-4c29-b173-0f0bf04769fb-2.jpeg'),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/4ed284f5-1c61-4605-ae8e-44edc9ce0e91-1.jpeg'),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/4ed284f5-1c61-4605-ae8e-44edc9ce0e91-2.jpeg'),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/4ed284f5-1c61-4605-ae8e-44edc9ce0e91-3.jpeg'),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/4ed284f5-1c61-4605-ae8e-44edc9ce0e91-4.jpeg'),
('7faf0793-3937-47f3-aa97-76ed81134c70', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/7faf0793-3937-47f3-aa97-76ed81134c70-1.jpeg'),
('7faf0793-3937-47f3-aa97-76ed81134c70', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/7faf0793-3937-47f3-aa97-76ed81134c70-2.jpeg'),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/8c32a8b1-c096-4f28-abd7-771ec5b02b1e-1.jpeg'),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/8c32a8b1-c096-4f28-abd7-771ec5b02b1e-2.jpeg'),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/8c32a8b1-c096-4f28-abd7-771ec5b02b1e-3.jpeg'),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/8c32a8b1-c096-4f28-abd7-771ec5b02b1e-4.jpeg'),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/8c32a8b1-c096-4f28-abd7-771ec5b02b1e-5.jpeg'),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/b1f3bbfd-e5da-4fe1-9add-eac66357d790-1.jpeg'),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/b1f3bbfd-e5da-4fe1-9add-eac66357d790-2.jpeg'),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/b1f3bbfd-e5da-4fe1-9add-eac66357d790-5.jpeg'),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/b1f3bbfd-e5da-4fe1-9add-eac66357d790-7.jpeg'),
('b68f14db-fac6-4b5c-8bb3-68a2ce7efbe9', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/b68f14db-fac6-4b5c-8bb3-68a2ce7efbe9-1.jpeg'),
('e3f29fb7-f830-43de-91ab-c67fd0c170a3', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/e3f29fb7-f830-43de-91ab-c67fd0c170a3-1.jpeg'),
('e3f29fb7-f830-43de-91ab-c67fd0c170a3', 'https://suechaokhai.s3.ap-southeast-1.amazonaws.com/properties/e3f29fb7-f830-43de-91ab-c67fd0c170a3-2.jpeg');

INSERT INTO selling_properties (property_id, price, is_sold) VALUES
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 2588830.71, FALSE),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 2588840.72, FALSE),
('2dd819db-6b5f-4c29-b173-0f0bf04769fb', 2588850.73, FALSE),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 2588860.74, FALSE),
('7faf0793-3937-47f3-aa97-76ed81134c70', 2588870.75, FALSE),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 2588880.76, FALSE),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 2588890.77, FALSE),
('b68f14db-fac6-4b5c-8bb3-68a2ce7efbe9', 2588900.78, FALSE),
('e3f29fb7-f830-43de-91ab-c67fd0c170a3', 2588910.79, FALSE);

INSERT INTO renting_properties (property_id, price_per_month, is_occupied) VALUES
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 15500.50, FALSE),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 15500.51, FALSE),
('2dd819db-6b5f-4c29-b173-0f0bf04769fb', 15500.52, FALSE),
('4ed284f5-1c61-4605-ae8e-44edc9ce0e91', 15500.53, FALSE),
('7faf0793-3937-47f3-aa97-76ed81134c70', 15500.54, FALSE),
('8c32a8b1-c096-4f28-abd7-771ec5b02b1e', 15500.55, FALSE),
('b1f3bbfd-e5da-4fe1-9add-eac66357d790', 15500.56, FALSE),
('b68f14db-fac6-4b5c-8bb3-68a2ce7efbe9', 15500.57, FALSE),
('e3f29fb7-f830-43de-91ab-c67fd0c170a3', 15500.58, FALSE);

INSERT INTO messages (message_id, sender_id, receiver_id, content, read_at, sent_at) VALUES
('541dfc60-2f5b-473a-ac09-76a2aa3e5276', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'Good morning' , NULL, '2024-02-25 19:04:18.818+07'),
('e74361f2-00de-40d8-b3fc-dc1f85547700', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'Hello mate' , NULL, '2024-02-25 19:04:27.436+07'),
('3f25b89f-b183-4ba8-b7b5-98d5f5fd374a', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'what are you up to?' , NULL, '2024-02-25 19:04:36.119+07'),
('f48c2f66-3450-41f1-8307-db6386187472', '62dd40da-f326-4825-9afc-2d68e06e0282', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'Hi' , NULL, '2024-02-25 19:05:10.519+07'),
('8d7a913b-0bd4-4554-8286-bc8ad2b8817e', '62dd40da-f326-4825-9afc-2d68e06e0282', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', '?' , NULL, '2024-02-25 19:05:12.953+07');

INSERT INTO appointments (property_id, owner_user_id, dweller_user_id, status, appointment_date, note) VALUES
('0bd03187-91ac-457d-957c-3ba2f6c0d24b', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'PENDING', '2024-02-21 15:50:00.000+07', NULL),
('21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', 'PENDING', '2024-02-21 15:51:00.000+07', 'Good morning');

INSERT INTO agreements (agreement_type, property_id, owner_user_id, dweller_user_id, agreement_date, status, deposit_amount, payment_per_month, payment_duration, total_payment, cancelled_message) VALUES
('RENTING', '0bd03187-91ac-457d-957c-3ba2f6c0d24b', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', '2024-02-21 15:50:00.000+07', 'AWAITING_DEPOSIT', 10000.00, 1000.00, 10000.00, 10, NULL),
('SELLING', '21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'f38f80b3-f326-4825-9afc-ebc331626555', '62dd40da-f326-4825-9afc-2d68e06e0282', '2024-02-22 15:51:00.000+07', 'AWAITING_DEPOSIT', 10000.00, 1000.00, 10000.00, 10, NULL),
('RENTING', '21b492b6-8d4f-45a6-af25-2fa9c1eb2042', 'f38f80b3-f326-4825-9afc-ebc331626555', 'bc5891ce-d6f2-d6f2-d6f2-ebc331626555', '2024-02-23 15:52:00.000+07', 'CANCELLED', 10000.00, 1000.00, 10000.00, 10, 'nope');

-------------------- VIEWS --------------------

ALTER TABLE users RENAME TO _users;
CREATE VIEW users AS SELECT * FROM _users WHERE deleted_at IS NULL;

ALTER TABLE user_financial_informations RENAME TO _user_financial_informations;
CREATE VIEW user_financial_informations AS SELECT * FROM _user_financial_informations WHERE user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL);

ALTER TABLE credit_cards RENAME TO _credit_cards;
CREATE VIEW credit_cards AS SELECT * FROM _credit_cards WHERE user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL);

ALTER TABLE user_verifications RENAME TO _user_verifications;
CREATE VIEW user_verifications AS SELECT * FROM _user_verifications WHERE user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL);

ALTER TABLE properties RENAME TO _properties;
CREATE VIEW properties AS SELECT *
    FROM _properties
    WHERE (
        deleted_at IS NULL AND
        owner_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL)
    );

ALTER TABLE property_images RENAME TO _property_images;
CREATE VIEW property_images AS SELECT * FROM _property_images WHERE property_id IN (SELECT property_id FROM properties WHERE deleted_at IS NULL);

ALTER TABLE selling_properties RENAME TO _selling_properties;
CREATE VIEW selling_properties AS SELECT * FROM _selling_properties WHERE property_id IN (SELECT property_id FROM properties WHERE deleted_at IS NULL);

ALTER TABLE renting_properties RENAME TO _renting_properties;
CREATE VIEW renting_properties AS SELECT * FROM _renting_properties WHERE property_id IN (SELECT property_id FROM properties WHERE deleted_at IS NULL);

ALTER TABLE appointments RENAME TO _appointments;
CREATE VIEW appointments AS SELECT *
    FROM _appointments
    WHERE (
     	deleted_at IS NULL AND
        property_id IN (SELECT property_id FROM properties WHERE deleted_at IS NULL) AND
        dweller_user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL) AND
        owner_user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL)
    );

ALTER TABLE agreements RENAME TO _agreements;
CREATE VIEW agreements AS SELECT *
    FROM _agreements
    WHERE (
        deleted_at IS NULL AND
        property_id IN (SELECT property_id FROM properties WHERE deleted_at IS NULL) AND
        dweller_user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL) AND
        owner_user_id IN (SELECT user_id FROM _users WHERE deleted_at IS NULL)
    );

-------------------- INDEX --------------------

CREATE INDEX idx_users_deleted_at                       ON _users (deleted_at);
CREATE INDEX idx_user_financial_information_deleted_at  ON _user_financial_informations (deleted_at);
CREATE INDEX idx_properties_deleted_at                  ON _properties (deleted_at);
CREATE INDEX idx_property_images_deleted_at             ON _property_images (deleted_at);
CREATE INDEX idx_selling_properties_deleted_at          ON _selling_properties (deleted_at);
CREATE INDEX idx_renting_properties_deleted_at          ON _renting_properties (deleted_at);
CREATE INDEX idx_appointments_deleted_at                ON _appointments (deleted_at);