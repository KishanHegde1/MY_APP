import * as Joi from "joi";

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  PORT: Joi.number().port().default(3000),
  API_PREFIX: Joi.string().default("api"),
  API_VERSION: Joi.string().pattern(/^\d+$/).default("1"),
  DATABASE_URL: Joi.string()
    .uri({ scheme: ["postgres", "postgresql"] })
    .optional(),
  DATABASE_DIRECT_URL: Joi.string()
    .uri({ scheme: ["postgres", "postgresql"] })
    .optional(),
  DATABASE_SSL: Joi.boolean().default(false),
  DATABASE_SYNCHRONIZE: Joi.boolean().default(false),
  DATABASE_LOGGING: Joi.boolean().default(false),
  DATABASE_POOL_MAX: Joi.number().integer().min(1).default(10),
  JWT_ACCESS_SECRET: Joi.string().min(16).optional(),
  JWT_ACCESS_EXPIRES_IN: Joi.string().default("15m"),
  JWT_REFRESH_SECRET: Joi.string().min(16).optional(),
  JWT_REFRESH_EXPIRES_IN: Joi.string().default("30d"),
  FIREBASE_PROJECT_ID: Joi.string().trim().min(1).optional(),
  // Empty values are valid in local development. Firebase Admin verification
  // becomes available only after all three Admin credentials are supplied.
  FIREBASE_CLIENT_EMAIL: Joi.string().trim().email().allow("").optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().trim().min(1).allow("").optional(),
  FIREBASE_CHECK_REVOKED_TOKENS: Joi.boolean().default(false),
  BCRYPT_ROUNDS: Joi.number().integer().min(10).max(15).default(12),
  CORS_ORIGIN: Joi.string().allow("").default(""),
  SWAGGER_ENABLED: Joi.boolean().default(true),
  RATE_LIMIT_TTL: Joi.number().integer().positive().default(60000),
  RATE_LIMIT_LIMIT: Joi.number().integer().positive().default(100),
  GOOGLE_ROUTES_API_KEY: Joi.string().trim().allow("").optional(),
  GOOGLE_ROUTES_TIMEOUT_MS: Joi.number()
    .integer()
    .min(1000)
    .max(30000)
    .default(8000),
  GOOGLE_PLACES_API_KEY: Joi.string().trim().allow("").optional(),
  GOOGLE_PLACES_TIMEOUT_MS: Joi.number()
    .integer()
    .min(1000)
    .max(30000)
    .default(5000),
  GOOGLE_PLACES_LANGUAGE_CODE: Joi.string()
    .trim()
    .pattern(/^[A-Za-z]{2,3}(?:-[A-Za-z]{2,4})?$/)
    .default("en"),
  GOOGLE_PLACES_REGION_CODE: Joi.string()
    .trim()
    .pattern(/^[A-Za-z]{2}$/)
    .default("IN"),
  LOCAL_RIDE_MIN_DISTANCE_KM: Joi.number().min(1).max(100).default(1),
  LOCAL_RIDE_MAX_DISTANCE_KM: Joi.number()
    .min(Joi.ref("LOCAL_RIDE_MIN_DISTANCE_KM"))
    .max(100)
    .default(100),
  PAYMENT_PROVIDER: Joi.string().trim().valid('', 'razorpay').default(''),
  RAZORPAY_KEY_ID: Joi.string().trim().allow('').optional(),
  RAZORPAY_KEY_SECRET: Joi.string().trim().allow('').optional(),
  RAZORPAY_WEBHOOK_SECRET: Joi.string().trim().allow('').optional(),
}).unknown(true);
