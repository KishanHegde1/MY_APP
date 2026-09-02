import {
  BadGatewayException,
  GatewayTimeoutException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ApplicationConfiguration } from "../../config/configuration";
import { ResolvePlaceDto } from "./dto/resolve-place.dto";
import { PlacesService } from "./places.service";

const request: ResolvePlaceDto = {
  query: "MG Road, Bengaluru",
  near: { latitude: 12.9716, longitude: 77.5946 },
};

describe("PlacesService", () => {
  afterEach(() => jest.restoreAllMocks());

  it("fails safely when the server Places key is absent", async () => {
    const service = createService(undefined);

    await expect(service.resolvePlace(request)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it("requests minimal Places fields and normalizes the best match", async () => {
    const fetchMock = jest.spyOn(global, "fetch").mockResolvedValue(
      jsonResponse({
        places: [
          {
            id: "ChIJplace",
            displayName: { text: "Mahatma Gandhi Road" },
            formattedAddress: "MG Road, Bengaluru, Karnataka, India",
            location: { latitude: 12.9756, longitude: 77.6064 },
          },
        ],
      }),
    );
    const service = createService("server-places-key");

    const result = await service.resolvePlace(request);

    expect(result).toEqual({
      query: request.query,
      source: "GOOGLE_PLACES_TEXT_SEARCH",
      place: {
        placeId: "ChIJplace",
        name: "Mahatma Gandhi Road",
        formattedAddress: "MG Road, Bengaluru, Karnataka, India",
        latitude: 12.9756,
        longitude: 77.6064,
      },
    });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, options] = fetchMock.mock.calls[0];
    expect(url).toBe("https://places.googleapis.com/v1/places:searchText");
    expect(options?.headers).toMatchObject({
      "X-Goog-Api-Key": "server-places-key",
      "X-Goog-FieldMask":
        "places.id,places.displayName,places.formattedAddress,places.location",
    });
    expect(JSON.parse(options?.body as string)).toMatchObject({
      textQuery: request.query,
      maxResultCount: 1,
      languageCode: "en",
      regionCode: "IN",
      locationBias: {
        circle: { center: request.near, radius: 50_000 },
      },
    });
  });

  it("returns null when Google Places finds no destination", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(jsonResponse({ places: [] }));
    const service = createService("server-places-key");

    await expect(service.resolvePlace(request)).resolves.toMatchObject({
      place: null,
    });
  });

  it("searches a typed pickup without inventing a location bias", async () => {
    const pickupRequest: ResolvePlaceDto = { query: "Kempegowda Airport" };
    const fetchMock = jest
      .spyOn(global, "fetch")
      .mockResolvedValue(jsonResponse({ places: [] }));
    const service = createService("server-places-key");

    await service.resolvePlace(pickupRequest);

    const [, options] = fetchMock.mock.calls[0];
    const body = JSON.parse(options?.body as string) as Record<string, unknown>;
    expect(body).not.toHaveProperty("locationBias");
    expect(body).toMatchObject({ textQuery: pickupRequest.query });
  });

  it("rejects invalid provider coordinates", async () => {
    jest.spyOn(global, "fetch").mockResolvedValue(
      jsonResponse({
        places: [
          {
            id: "ChIJplace",
            displayName: { text: "Bad place" },
            formattedAddress: "Bad place",
            location: { latitude: 900, longitude: 77.6064 },
          },
        ],
      }),
    );
    const service = createService("server-places-key");

    await expect(service.resolvePlace(request)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it("returns a gateway timeout when the provider request is aborted", async () => {
    const abortError = new Error("provider request aborted");
    abortError.name = "AbortError";
    jest.spyOn(global, "fetch").mockRejectedValue(abortError);
    const service = createService("server-places-key");

    await expect(service.resolvePlace(request)).rejects.toBeInstanceOf(
      GatewayTimeoutException,
    );
  });
});

function createService(apiKey: string | undefined): PlacesService {
  const configService = {
    get: jest.fn().mockImplementation((key: keyof ApplicationConfiguration) => {
      if (key === "maps") {
        return {
          routesApiKey: undefined,
          routesTimeoutMs: 8000,
          placesApiKey: apiKey,
          placesTimeoutMs: 5000,
          placesLanguageCode: "en",
          placesRegionCode: "IN",
        };
      }
      return undefined;
    }),
  } as unknown as ConfigService<ApplicationConfiguration, true>;
  return new PlacesService(configService);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
