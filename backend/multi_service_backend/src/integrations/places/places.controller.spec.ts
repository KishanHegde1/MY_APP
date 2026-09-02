import {
  INestApplication,
  ValidationPipe,
  VersioningType,
} from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { ThrottlerModule } from "@nestjs/throttler";
import { Server } from "http";
import request from "supertest";
import { GlobalExceptionFilter } from "../../common/filters/global-exception.filter";
import { ResponseInterceptor } from "../../common/interceptors/response.interceptor";
import { PlacesModule } from "./places.module";
import { PlacesService } from "./places.service";
import { ResolvePlaceResult } from "./places.types";

describe("PlacesController", () => {
  let app: INestApplication;
  const resolvePlace = jest.fn<Promise<ResolvePlaceResult>, [unknown]>();

  beforeAll(async () => {
    const testingModule = await Test.createTestingModule({
      imports: [
        ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }]),
        PlacesModule,
      ],
    })
      .overrideProvider(PlacesService)
      .useValue({ resolvePlace })
      .compile();
    app = testingModule.createNestApplication();
    app.setGlobalPrefix("api");
    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: "1",
    });
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new ResponseInterceptor());
    await app.init();
  });

  afterAll(async () => app.close());
  afterEach(() => resolvePlace.mockReset());

  it("registers POST /api/v1/maps/places/resolve", async () => {
    const result: ResolvePlaceResult = {
      query: "MG Road",
      source: "GOOGLE_PLACES_TEXT_SEARCH",
      place: {
        placeId: "ChIJplace",
        name: "MG Road",
        formattedAddress: "MG Road, Bengaluru, Karnataka, India",
        latitude: 12.9756,
        longitude: 77.6064,
      },
    };
    resolvePlace.mockResolvedValue(result);
    const body = {
      query: "MG Road",
      near: { latitude: 12.9716, longitude: 77.5946 },
    };

    const response = await request(app.getHttpServer() as Server)
      .post("/api/v1/maps/places/resolve")
      .send(body)
      .expect(200);

    expect(response.body).toEqual({ success: true, data: result });
    expect(resolvePlace).toHaveBeenCalledWith(body);
  });

  it("rejects short destination queries", async () => {
    await request(app.getHttpServer() as Server)
      .post("/api/v1/maps/places/resolve")
      .send({
        query: "MG",
        near: { latitude: 12.9716, longitude: 77.5946 },
      })
      .expect(400);

    expect(resolvePlace).not.toHaveBeenCalled();
  });

  it("accepts a typed pickup without a nearby GPS coordinate", async () => {
    const body = { query: "Kempegowda Airport" };
    resolvePlace.mockResolvedValue({
      query: body.query,
      place: null,
      source: "GOOGLE_PLACES_TEXT_SEARCH",
    });

    await request(app.getHttpServer() as Server)
      .post("/api/v1/maps/places/resolve")
      .send(body)
      .expect(200);

    expect(resolvePlace).toHaveBeenCalledWith(body);
  });
});
