import { envValidationSchema } from "./env.validation";

describe("local ride environment validation", () => {
  it("applies the 1 km and 100 km defaults", () => {
    const result = envValidationSchema.validate({});

    expect(result.error).toBeUndefined();
    expect(result.value).toMatchObject({
      LOCAL_RIDE_MIN_DISTANCE_KM: 1,
      LOCAL_RIDE_MAX_DISTANCE_KM: 100,
    });
  });

  it.each([
    { LOCAL_RIDE_MIN_DISTANCE_KM: 0, LOCAL_RIDE_MAX_DISTANCE_KM: 100 },
    { LOCAL_RIDE_MIN_DISTANCE_KM: 1, LOCAL_RIDE_MAX_DISTANCE_KM: 101 },
    { LOCAL_RIDE_MIN_DISTANCE_KM: 50, LOCAL_RIDE_MAX_DISTANCE_KM: 49 },
  ])("rejects an invalid distance policy", (environment) => {
    const result = envValidationSchema.validate(environment);

    expect(result.error).toBeDefined();
  });

  it.each([
    { LOCAL_RIDE_MIN_DISTANCE_KM: "1", LOCAL_RIDE_MAX_DISTANCE_KM: "1" },
    { LOCAL_RIDE_MIN_DISTANCE_KM: "100", LOCAL_RIDE_MAX_DISTANCE_KM: "100" },
  ])("accepts inclusive boundary values", (environment) => {
    const result = envValidationSchema.validate(environment);

    expect(result.error).toBeUndefined();
  });

  it("allows empty Firebase Admin credentials for local development", () => {
    const result = envValidationSchema.validate({
      FIREBASE_PROJECT_ID: "multi-service-1f99d",
      FIREBASE_CLIENT_EMAIL: "",
      FIREBASE_PRIVATE_KEY: "",
    });

    expect(result.error).toBeUndefined();
  });
});
