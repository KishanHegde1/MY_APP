import {
  BadRequestException,
  BadGatewayException,
  GatewayTimeoutException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ApplicationConfiguration } from "../../config/configuration";
import {
  ComputeRoutesDto,
  RideVehicleType,
  RoutePointDto,
} from "./dto/compute-routes.dto";
import {
  ComputedRoute,
  ComputeRoutesResult,
  ProviderTravelMode,
  RouteFareEstimate,
} from "./maps.types";

const GOOGLE_ROUTES_URL =
  "https://routes.googleapis.com/directions/v2:computeRoutes";
const GOOGLE_ROUTES_FIELD_MASK = [
  "routes.routeLabels",
  "routes.distanceMeters",
  "routes.duration",
  "routes.staticDuration",
  "routes.polyline.encodedPolyline",
].join(",");
const MAX_ENCODED_POLYLINE_LENGTH = 500_000;

const FARE_DISCLAIMER =
  "Indicative estimate only. The final booking fare can change after driver assignment and may include tolls, taxes, waiting time, or demand pricing.";

interface FareRate {
  vehicleType: RideVehicleType;
  baseFare: number;
  perKilometer: number;
  perMinute: number;
  minimumFare: number;
}

const FARE_RATES: readonly FareRate[] = [
  {
    vehicleType: RideVehicleType.bike,
    baseFare: 35,
    perKilometer: 8,
    perMinute: 0.5,
    minimumFare: 45,
  },
  {
    vehicleType: RideVehicleType.auto,
    baseFare: 45,
    perKilometer: 12,
    perMinute: 0.75,
    minimumFare: 60,
  },
  {
    vehicleType: RideVehicleType.car,
    baseFare: 75,
    perKilometer: 16,
    perMinute: 1,
    minimumFare: 100,
  },
];

interface GoogleRoute {
  routeLabels?: unknown;
  distanceMeters?: unknown;
  duration?: unknown;
  staticDuration?: unknown;
  polyline?: { encodedPolyline?: unknown };
}

interface GoogleRoutesResponse {
  routes?: unknown;
}

interface LocalRideDistancePolicy {
  minimumKilometers: number;
  maximumKilometers: number;
  minimumMeters: number;
  maximumMeters: number;
}

@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);

  constructor(
    private readonly configService: ConfigService<
      ApplicationConfiguration,
      true
    >,
  ) {}

  async computeRoutes(request: ComputeRoutesDto): Promise<ComputeRoutesResult> {
    const mapsConfig =
      this.configService.get<ApplicationConfiguration["maps"]>("maps");
    const distancePolicy = this.getDistancePolicy();
    const apiKey = mapsConfig?.routesApiKey?.trim();
    if (!apiKey) {
      throw new ServiceUnavailableException(
        "Route planning is not configured yet.",
      );
    }

    const alternativesRequested = request.alternatives ?? true;
    const vehicleType = request.vehicleType ?? RideVehicleType.car;
    const providerTravelMode: ProviderTravelMode =
      vehicleType === RideVehicleType.bike ? "TWO_WHEELER" : "DRIVE";
    const timeoutMs = mapsConfig?.routesTimeoutMs ?? 8000;
    const providerResponse = await this.requestGoogleRoutes(
      apiKey,
      timeoutMs,
      request.origin,
      request.destination,
      alternativesRequested,
      providerTravelMode,
    );
    const routes = this.normalizeRoutes(providerResponse, vehicleType);
    const localRoutes = this.applyDistancePolicy(routes, distancePolicy);

    return {
      origin: request.origin,
      destination: request.destination,
      vehicleType,
      providerTravelMode,
      alternativesRequested,
      generatedAt: new Date().toISOString(),
      routes: localRoutes,
      fareDisclaimer: FARE_DISCLAIMER,
    };
  }

  private getDistancePolicy(): LocalRideDistancePolicy {
    const config =
      this.configService.get<ApplicationConfiguration["localRides"]>(
        "localRides",
      );
    const minimumKilometers = config?.minDistanceKm ?? 1;
    const maximumKilometers = config?.maxDistanceKm ?? 100;
    if (
      !Number.isFinite(minimumKilometers) ||
      !Number.isFinite(maximumKilometers) ||
      minimumKilometers < 1 ||
      minimumKilometers > 100 ||
      maximumKilometers < 1 ||
      maximumKilometers > 100 ||
      maximumKilometers < minimumKilometers
    ) {
      this.logger.error("Invalid local ride distance policy configuration.");
      throw new ServiceUnavailableException(
        "The local ride distance policy is not configured correctly.",
      );
    }

    return {
      minimumKilometers,
      maximumKilometers,
      minimumMeters: minimumKilometers * 1000,
      maximumMeters: maximumKilometers * 1000,
    };
  }

  private applyDistancePolicy(
    routes: ComputedRoute[],
    policy: LocalRideDistancePolicy,
  ): ComputedRoute[] {
    if (routes.length === 0) return [];
    const eligibleRoutes = routes.filter(
      (route) =>
        route.distanceMeters >= policy.minimumMeters &&
        route.distanceMeters <= policy.maximumMeters,
    );
    if (eligibleRoutes.length > 0) return eligibleRoutes;

    const distances = routes.map((route) => route.distanceMeters);
    if (Math.max(...distances) < policy.minimumMeters) {
      throw new BadRequestException(
        `Local rides must be at least ${policy.minimumKilometers} km. Choose a farther destination.`,
      );
    }
    if (Math.min(...distances) > policy.maximumMeters) {
      throw new BadRequestException(
        `Local rides cannot exceed ${policy.maximumKilometers} km. Please choose an outstation ride.`,
      );
    }
    throw new BadRequestException(
      `No available route is within the ${policy.minimumKilometers}-${policy.maximumKilometers} km local ride range.`,
    );
  }

  private async requestGoogleRoutes(
    apiKey: string,
    timeoutMs: number,
    origin: RoutePointDto,
    destination: RoutePointDto,
    alternatives: boolean,
    travelMode: ProviderTravelMode,
  ): Promise<GoogleRoutesResponse> {
    const abortController = new AbortController();
    const timeout = setTimeout(() => abortController.abort(), timeoutMs);

    try {
      const response = await fetch(GOOGLE_ROUTES_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": GOOGLE_ROUTES_FIELD_MASK,
        },
        body: JSON.stringify({
          origin: this.toGoogleWaypoint(origin),
          destination: this.toGoogleWaypoint(destination),
          travelMode,
          routingPreference: "TRAFFIC_AWARE",
          computeAlternativeRoutes: alternatives,
          polylineQuality: "HIGH_QUALITY",
          polylineEncoding: "ENCODED_POLYLINE",
          languageCode: "en-IN",
          units: "METRIC",
        }),
        signal: abortController.signal,
      });

      if (!response.ok) {
        this.logger.warn(
          `Google Routes request failed with HTTP ${response.status}.`,
        );
        if (
          response.status === HttpStatusCode.tooManyRequests ||
          response.status === HttpStatusCode.forbidden
        ) {
          throw new ServiceUnavailableException(
            "Route planning is temporarily unavailable.",
          );
        }
        throw new BadGatewayException(
          "The route provider could not complete this request.",
        );
      }

      try {
        return (await response.json()) as GoogleRoutesResponse;
      } catch {
        throw new BadGatewayException(
          "The route provider returned an invalid response.",
        );
      }
    } catch (error: unknown) {
      if (
        error instanceof ServiceUnavailableException ||
        error instanceof BadGatewayException
      )
        throw error;
      if (error instanceof Error && error.name === "AbortError") {
        throw new GatewayTimeoutException(
          "Route planning timed out. Please try again.",
        );
      }
      this.logger.warn(
        "Google Routes request failed before a response was received.",
      );
      throw new BadGatewayException(
        "Route planning is temporarily unavailable.",
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  private normalizeRoutes(
    response: GoogleRoutesResponse,
    vehicleType: RideVehicleType,
  ): ComputedRoute[] {
    if (typeof response !== "object" || response === null) {
      throw new BadGatewayException(
        "The route provider returned an invalid response.",
      );
    }
    if (response.routes === undefined) return [];
    if (!Array.isArray(response.routes))
      throw new BadGatewayException(
        "The route provider returned an invalid response.",
      );

    return response.routes.map((route: unknown, index: number) =>
      this.normalizeRoute(route, index, vehicleType),
    );
  }

  private normalizeRoute(
    route: unknown,
    index: number,
    vehicleType: RideVehicleType,
  ): ComputedRoute {
    if (!this.isGoogleRoute(route)) {
      throw new BadGatewayException(
        "The route provider returned an invalid route.",
      );
    }

    const distanceMeters = this.readNonNegativeNumber(route.distanceMeters);
    const durationSeconds = this.parseGoogleDuration(route.duration);
    const staticDurationSeconds = this.parseGoogleDuration(
      route.staticDuration,
    );
    const encodedPolyline = route.polyline?.encodedPolyline;
    if (
      distanceMeters === undefined ||
      durationSeconds === undefined ||
      staticDurationSeconds === undefined ||
      typeof encodedPolyline !== "string" ||
      encodedPolyline.length === 0 ||
      encodedPolyline.length > MAX_ENCODED_POLYLINE_LENGTH
    ) {
      throw new BadGatewayException(
        "The route provider returned an incomplete route.",
      );
    }

    const providerLabels = Array.isArray(route.routeLabels)
      ? route.routeLabels.filter(
          (label: unknown): label is string => typeof label === "string",
        )
      : [];
    const isRecommended =
      index === 0 || providerLabels.includes("DEFAULT_ROUTE");

    return {
      id: `route-${index + 1}`,
      isRecommended,
      isAlternative:
        !isRecommended || providerLabels.includes("DEFAULT_ROUTE_ALTERNATE"),
      providerLabels,
      distanceMeters: Math.round(distanceMeters),
      distanceKilometers: this.round(distanceMeters / 1000, 2),
      durationSeconds,
      durationMinutes: Math.ceil(durationSeconds / 60),
      staticDurationSeconds,
      trafficDelaySeconds: Math.max(0, durationSeconds - staticDurationSeconds),
      encodedPolyline,
      fareEstimates: this.estimateFares(
        distanceMeters,
        durationSeconds,
        vehicleType,
      ),
    };
  }

  private estimateFares(
    distanceMeters: number,
    durationSeconds: number,
    vehicleType: RideVehicleType,
  ): RouteFareEstimate[] {
    const kilometers = distanceMeters / 1000;
    const minutes = durationSeconds / 60;

    return FARE_RATES.filter((rate) => rate.vehicleType === vehicleType).map(
      (rate): RouteFareEstimate => {
        const calculatedFare =
          rate.baseFare +
          kilometers * rate.perKilometer +
          minutes * rate.perMinute;
        const estimatedAmount = Math.round(
          Math.max(rate.minimumFare, calculatedFare),
        );
        return {
          vehicleType: rate.vehicleType,
          currency: "INR",
          estimatedAmount,
          estimatedRange: {
            minimum: Math.floor(estimatedAmount * 0.9),
            maximum: Math.ceil(estimatedAmount * 1.15),
          },
          isEstimate: true,
          pricingModel: "INDICATIVE_DISTANCE_TIME_V1",
        };
      },
    );
  }

  private toGoogleWaypoint(point: RoutePointDto): object {
    return {
      location: {
        latLng: { latitude: point.latitude, longitude: point.longitude },
      },
    };
  }

  private isGoogleRoute(value: unknown): value is GoogleRoute {
    return typeof value === "object" && value !== null;
  }

  private readNonNegativeNumber(value: unknown): number | undefined {
    return typeof value === "number" && Number.isFinite(value) && value >= 0
      ? value
      : undefined;
  }

  private parseGoogleDuration(value: unknown): number | undefined {
    if (typeof value !== "string") return undefined;
    const match = /^(\d+(?:\.\d+)?)s$/.exec(value);
    if (!match) return undefined;
    const seconds = Number(match[1]);
    return Number.isFinite(seconds) ? Math.ceil(seconds) : undefined;
  }

  private round(value: number, decimalPlaces: number): number {
    const multiplier = 10 ** decimalPlaces;
    return Math.round(value * multiplier) / multiplier;
  }
}

const HttpStatusCode = {
  forbidden: 403,
  tooManyRequests: 429,
} as const;
