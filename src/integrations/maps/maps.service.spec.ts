import {
  BadGatewayException,
  GatewayTimeoutException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ApplicationConfiguration } from "../../config/configuration";
import { ComputeRoutesDto, RideVehicleType } from "./dto/compute-routes.dto";
import { MapsService } from "./maps.service";

const request: ComputeRoutesDto = {
  origin: { latitude: 12.9716, longitude: 77.5946 },
  destination: { latitude: 12.9352, longitude: 77.6245 },
};

const googleRoute = {
  routeLabels: ["DEFAULT_ROUTE"],
  distanceMeters: 10000,
  duration: "1800s",
  staticDuration: "1500s",
  polyline: { encodedPolyline: "encoded-route" },
};

describe("MapsService", () => {
  afterEach(() => jest.restoreAllMocks());

  it("fails safely without making a provider request when the key is absent", async () => {
    const fetchSpy = jest.spyOn(global, "fetch");
    const service = createService(undefined);

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("requests explicit Google Routes fields and normalizes routes and fare estimates", async () => {
    const fetchSpy = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ routes: [googleRoute] }));
    const service = createService("server-only-key");

    const result = await service.computeRoutes(request);

    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const [url, init] = fetchSpy.mock.calls[0];
    expect(url).toBe(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );
    expect(init?.headers).toEqual({
      "Content-Type": "application/json",
      "X-Goog-Api-Key": "server-only-key",
      "X-Goog-FieldMask":
        "routes.routeLabels,routes.distanceMeters,routes.duration,routes.staticDuration,routes.polyline.encodedPolyline",
    });
    expect(init?.body).toBe(
      JSON.stringify({
        origin: { location: { latLng: request.origin } },
        destination: { location: { latLng: request.destination } },
        travelMode: "DRIVE",
        routingPreference: "TRAFFIC_AWARE",
        computeAlternativeRoutes: true,
        polylineQuality: "HIGH_QUALITY",
        polylineEncoding: "ENCODED_POLYLINE",
        languageCode: "en-IN",
        units: "METRIC",
      }),
    );

    expect(result.routes).toHaveLength(1);
    expect(result.routes[0]).toMatchObject({
      id: "route-1",
      isRecommended: true,
      isAlternative: false,
      distanceMeters: 10000,
      distanceKilometers: 10,
      durationSeconds: 1800,
      durationMinutes: 30,
      staticDurationSeconds: 1500,
      trafficDelaySeconds: 300,
      encodedPolyline: "encoded-route",
    });
    expect(result).toMatchObject({
      vehicleType: RideVehicleType.car,
      providerTravelMode: "DRIVE",
    });
    expect(result.routes[0].fareEstimates).toEqual([
      {
        vehicleType: "CAR",
        currency: "INR",
        estimatedAmount: 265,
        estimatedRange: { minimum: 238, maximum: 305 },
        isEstimate: true,
        pricingModel: "INDICATIVE_DISTANCE_TIME_V1",
      },
    ]);
    expect(result.fareDisclaimer).toContain("Indicative estimate only");
  });

  it("uses two-wheeler route geometry and bike pricing for a bike request", async () => {
    const fetchSpy = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ routes: [googleRoute] }));
    const service = createService("server-only-key");

    const result = await service.computeRoutes({
      ...request,
      vehicleType: RideVehicleType.bike,
    });

    const providerBody = fetchSpy.mock.calls[0][1]?.body;
    if (typeof providerBody !== "string")
      throw new Error("Expected a JSON request body.");
    expect(providerBody).toContain('"travelMode":"TWO_WHEELER"');
    expect(result).toMatchObject({
      vehicleType: RideVehicleType.bike,
      providerTravelMode: "TWO_WHEELER",
    });
    expect(result.routes[0].fareEstimates).toEqual([
      expect.objectContaining({
        vehicleType: RideVehicleType.bike,
        estimatedAmount: 130,
        isEstimate: true,
      }),
    ]);
  });

  it("rejects routes below the configured local-ride minimum", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        jsonResponse({ routes: [{ ...googleRoute, distanceMeters: 999 }] }),
      );
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toMatchObject({
      status: 400,
      response: {
        message:
          "Local rides must be at least 1 km. Choose a farther destination.",
      },
    });
  });

  it("rejects routes above the configured local-ride maximum", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(
        jsonResponse({ routes: [{ ...googleRoute, distanceMeters: 100_001 }] }),
      );
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toMatchObject({
      status: 400,
      response: {
        message:
          "Local rides cannot exceed 100 km. Please choose an outstation ride.",
      },
    });
  });

  it("filters Google alternatives outside the configured distance range", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      jsonResponse({
        routes: [
          { ...googleRoute, distanceMeters: 500 },
          { ...googleRoute, distanceMeters: 10_000 },
          { ...googleRoute, distanceMeters: 100_001 },
        ],
      }),
    );
    const service = createService("server-only-key");

    const result = await service.computeRoutes(request);

    expect(result.routes).toHaveLength(1);
    expect(result.routes[0]).toMatchObject({
      id: "route-2",
      distanceMeters: 10_000,
    });
  });

  it("accepts routes exactly on both inclusive distance boundaries", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      jsonResponse({
        routes: [
          { ...googleRoute, distanceMeters: 1_000 },
          { ...googleRoute, distanceMeters: 100_000 },
        ],
      }),
    );
    const service = createService("server-only-key");

    const result = await service.computeRoutes(request);

    expect(result.routes.map((route) => route.distanceMeters)).toEqual([
      1_000, 100_000,
    ]);
  });

  it("fails safely when the injected distance policy is inconsistent", async () => {
    const fetchSpy = jest.spyOn(global, "fetch");
    const service = createService("server-only-key", {
      minDistanceKm: 50,
      maxDistanceKm: 10,
    });

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("passes an explicit alternatives opt-out to Google Routes", async () => {
    const fetchSpy = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ routes: [] }));
    const service = createService("server-only-key");

    const result = await service.computeRoutes({
      ...request,
      alternatives: false,
    });

    const providerBody = fetchSpy.mock.calls[0][1]?.body;
    expect(typeof providerBody).toBe("string");
    if (typeof providerBody !== "string")
      throw new Error("Expected a JSON request body.");
    expect(providerBody).toContain('"computeAlternativeRoutes":false');
    expect(result.alternativesRequested).toBe(false);
    expect(result.routes).toEqual([]);
  });

  it("returns a sanitized gateway error for an invalid provider payload", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ routes: "not-an-array" }));
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it.each(["", "x".repeat(500_001)])(
    "rejects an invalid encoded polyline",
    async (encodedPolyline) => {
      jest.spyOn(global, "fetch").mockResolvedValue(
        jsonResponse({
          routes: [{ ...googleRoute, polyline: { encodedPolyline } }],
        }),
      );
      const service = createService("server-only-key");

      await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
        BadGatewayException,
      );
    },
  );

  it("treats an omitted routes collection as no route found", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(jsonResponse({}));
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).resolves.toMatchObject({
      routes: [],
    });
  });

  it("returns a gateway timeout when the provider request is aborted", async () => {
    const abortError = new Error("provider request aborted");
    abortError.name = "AbortError";
    jest.spyOn(global, "fetch").mockRejectedValue(abortError);
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      GatewayTimeoutException,
    );
  });

  it.each([403, 429])(
    "sanitizes a provider HTTP %i response as temporary unavailability",
    async (status) => {
      jest
        .spyOn(global, "fetch")
        .mockResolvedValue(
          jsonResponse(
            { error: { message: "private provider detail" } },
            status,
          ),
        );
      const service = createService("server-only-key");

      await expect(service.computeRoutes(request)).rejects.toMatchObject({
        status: 503,
        response: { message: "Route planning is temporarily unavailable." },
      });
    },
  );

  it("sanitizes a provider server error as a bad gateway", async () => {
    jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ error: "provider detail" }, 500));
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it("rejects invalid provider JSON", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      new Response("not-json", {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
    const service = createService("server-only-key");

    await expect(service.computeRoutes(request)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });
});

function createService(
  apiKey: string | undefined,
  distancePolicy: ApplicationConfiguration["localRides"] = {
    minDistanceKm: 1,
    maxDistanceKm: 100,
  },
): MapsService {
  const configService = {
    get: jest.fn().mockImplementation((key: keyof ApplicationConfiguration) => {
      if (key === "maps")
        return { routesApiKey: apiKey, routesTimeoutMs: 8000 };
      if (key === "localRides") return distancePolicy;
      return undefined;
    }),
  } as unknown as ConfigService<ApplicationConfiguration, true>;
  return new MapsService(configService);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
