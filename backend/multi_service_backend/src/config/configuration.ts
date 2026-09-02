export interface ApplicationConfiguration {
  app: {
    environment: string;
    port: number;
    apiPrefix: string;
    apiVersion: string;
    corsOrigins: string[];
  };
  database: {
    url?: string;
    directUrl?: string;
    ssl: boolean;
    synchronize: boolean;
    logging: boolean;
    poolMax: number;
  };
  jwt: {
    accessSecret: string;
    accessExpiresIn: string;
    refreshSecret: string;
    refreshExpiresIn: string;
  };
  firebase: {
    projectId?: string;
    clientEmail?: string;
    privateKey?: string;
    checkRevokedTokens: boolean;
  };
  maps: {
    routesApiKey?: string;
    routesTimeoutMs: number;
    placesApiKey?: string;
    placesTimeoutMs: number;
    placesLanguageCode: string;
    placesRegionCode: string;
  };
  localRides: { minDistanceKm: number; maxDistanceKm: number };
  payments: {
    provider?: string;
    razorpayKeyId?: string;
    razorpayKeySecret?: string;
  };
  swagger: { enabled: boolean };
}

const asBoolean = (value: string | undefined, fallback = false): boolean =>
  value?.toLowerCase() === "true" || (value === undefined && fallback);

export default (): ApplicationConfiguration => ({
  app: {
    environment: process.env.NODE_ENV ?? "development",
    port: Number(process.env.PORT ?? 3000),
    apiPrefix: process.env.API_PREFIX ?? "api",
    apiVersion: process.env.API_VERSION ?? "1",
    corsOrigins: (process.env.CORS_ORIGIN ?? "").split(",").filter(Boolean),
  },
  database: {
    url: process.env.DATABASE_URL,
    directUrl: process.env.DATABASE_DIRECT_URL,
    ssl: asBoolean(process.env.DATABASE_SSL),
    synchronize: asBoolean(process.env.DATABASE_SYNCHRONIZE),
    logging: asBoolean(process.env.DATABASE_LOGGING),
    poolMax: Number(process.env.DATABASE_POOL_MAX ?? 10),
  },
  jwt: {
    accessSecret:
      process.env.JWT_ACCESS_SECRET ?? "development-access-secret-change-me",
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? "15m",
    refreshSecret:
      process.env.JWT_REFRESH_SECRET ?? "development-refresh-secret-change-me",
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? "30d",
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID?.trim() || undefined,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL?.trim() || undefined,
    privateKey:
      process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n").trim() ||
      undefined,
    checkRevokedTokens: asBoolean(
      process.env.FIREBASE_CHECK_REVOKED_TOKENS,
    ),
  },
  maps: {
    routesApiKey: process.env.GOOGLE_ROUTES_API_KEY?.trim() || undefined,
    routesTimeoutMs: Number(process.env.GOOGLE_ROUTES_TIMEOUT_MS ?? 8000),
    placesApiKey: process.env.GOOGLE_PLACES_API_KEY?.trim() || undefined,
    placesTimeoutMs: Number(process.env.GOOGLE_PLACES_TIMEOUT_MS ?? 5000),
    placesLanguageCode: process.env.GOOGLE_PLACES_LANGUAGE_CODE?.trim() || "en",
    placesRegionCode: process.env.GOOGLE_PLACES_REGION_CODE?.trim() || "IN",
  },
  localRides: {
    minDistanceKm: Number(process.env.LOCAL_RIDE_MIN_DISTANCE_KM ?? 1),
    maxDistanceKm: Number(process.env.LOCAL_RIDE_MAX_DISTANCE_KM ?? 100),
  },
  payments: {
    provider: process.env.PAYMENT_PROVIDER?.trim().toLowerCase() || undefined,
    razorpayKeyId: process.env.RAZORPAY_KEY_ID?.trim() || undefined,
    razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET?.trim() || undefined,
  },
  swagger: { enabled: asBoolean(process.env.SWAGGER_ENABLED, true) },
});
