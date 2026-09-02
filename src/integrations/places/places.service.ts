import {
  BadGatewayException,
  GatewayTimeoutException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ApplicationConfiguration } from "../../config/configuration";
import { ResolvePlaceDto } from "./dto/resolve-place.dto";
import { ResolvedPlace, ResolvePlaceResult } from "./places.types";

const GOOGLE_PLACES_TEXT_SEARCH_URL =
  "https://places.googleapis.com/v1/places:searchText";
const GOOGLE_PLACES_FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
].join(",");
const LOCATION_BIAS_RADIUS_METERS = 50_000;

interface GooglePlace {
  id?: unknown;
  displayName?: { text?: unknown };
  formattedAddress?: unknown;
  location?: { latitude?: unknown; longitude?: unknown };
}

interface GooglePlacesResponse {
  places?: unknown;
}

@Injectable()
export class PlacesService {
  private readonly logger = new Logger(PlacesService.name);

  constructor(
    private readonly configService: ConfigService<
      ApplicationConfiguration,
      true
    >,
  ) {}

  async resolvePlace(request: ResolvePlaceDto): Promise<ResolvePlaceResult> {
    const mapsConfig =
      this.configService.get<ApplicationConfiguration["maps"]>("maps");
    const apiKey = mapsConfig?.placesApiKey?.trim();
    if (!apiKey) {
      throw new ServiceUnavailableException(
        "Destination search is not configured yet.",
      );
    }

    const response = await this.requestGooglePlaces(
      apiKey,
      mapsConfig?.placesTimeoutMs ?? 5000,
      request,
      mapsConfig?.placesLanguageCode || "en",
      mapsConfig?.placesRegionCode || "IN",
    );

    return {
      query: request.query.trim(),
      place: this.firstPlace(response),
      source: "GOOGLE_PLACES_TEXT_SEARCH",
    };
  }

  private async requestGooglePlaces(
    apiKey: string,
    timeoutMs: number,
    request: ResolvePlaceDto,
    languageCode: string,
    regionCode: string,
  ): Promise<GooglePlacesResponse> {
    const abortController = new AbortController();
    const timeout = setTimeout(() => abortController.abort(), timeoutMs);

    try {
      const response = await fetch(GOOGLE_PLACES_TEXT_SEARCH_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": GOOGLE_PLACES_FIELD_MASK,
        },
        body: JSON.stringify({
          textQuery: request.query.trim(),
          maxResultCount: 1,
          ...(request.near
            ? {
                locationBias: {
                  circle: {
                    center: request.near,
                    radius: LOCATION_BIAS_RADIUS_METERS,
                  },
                },
              }
            : {}),
          languageCode,
          regionCode: regionCode.toUpperCase(),
        }),
        signal: abortController.signal,
      });

      if (!response.ok) {
        this.logger.warn(
          `Google Places request failed with HTTP ${response.status}.`,
        );
        if (response.status === 403 || response.status === 429) {
          throw new ServiceUnavailableException(
            "Destination search is temporarily unavailable.",
          );
        }
        throw new BadGatewayException(
          "The destination provider could not complete this request.",
        );
      }

      try {
        return (await response.json()) as GooglePlacesResponse;
      } catch {
        throw new BadGatewayException(
          "The destination provider returned an invalid response.",
        );
      }
    } catch (error: unknown) {
      if (
        error instanceof ServiceUnavailableException ||
        error instanceof BadGatewayException
      ) {
        throw error;
      }
      if (error instanceof Error && error.name === "AbortError") {
        throw new GatewayTimeoutException(
          "Destination search timed out. Please try again.",
        );
      }
      this.logger.warn(
        "Google Places request failed before a response was received.",
      );
      throw new BadGatewayException(
        "Destination search is temporarily unavailable.",
      );
    } finally {
      clearTimeout(timeout);
    }
  }

  private firstPlace(response: GooglePlacesResponse): ResolvedPlace | null {
    if (typeof response !== "object" || response === null) {
      throw new BadGatewayException(
        "The destination provider returned an invalid response.",
      );
    }
    if (response.places === undefined) return null;
    if (!Array.isArray(response.places)) {
      throw new BadGatewayException(
        "The destination provider returned an invalid response.",
      );
    }
    if (response.places.length === 0) return null;

    const rawPlace: unknown = (response.places as unknown[])[0];
    if (
      typeof rawPlace !== "object" ||
      rawPlace === null ||
      Array.isArray(rawPlace)
    ) {
      throw new BadGatewayException(
        "The destination provider returned an invalid response.",
      );
    }
    const place = rawPlace as GooglePlace;
    const placeId = this.requiredString(place.id);
    const name = this.requiredString(place.displayName?.text);
    const formattedAddress = this.requiredString(place.formattedAddress);
    const latitude = this.coordinate(place.location?.latitude, -90, 90);
    const longitude = this.coordinate(place.location?.longitude, -180, 180);

    return { placeId, name, formattedAddress, latitude, longitude };
  }

  private requiredString(value: unknown): string {
    if (typeof value !== "string" || value.trim().length === 0) {
      throw new BadGatewayException(
        "The destination provider returned an invalid response.",
      );
    }
    return value.trim();
  }

  private coordinate(value: unknown, minimum: number, maximum: number): number {
    if (
      typeof value !== "number" ||
      !Number.isFinite(value) ||
      value < minimum ||
      value > maximum
    ) {
      throw new BadGatewayException(
        "The destination provider returned an invalid response.",
      );
    }
    return value;
  }
}
