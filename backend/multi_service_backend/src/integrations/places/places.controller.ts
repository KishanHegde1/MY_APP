import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  Version,
} from "@nestjs/common";
import { ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { Throttle, ThrottlerGuard } from "@nestjs/throttler";
import { ResolvePlaceDto } from "./dto/resolve-place.dto";
import { PlacesService } from "./places.service";
import { ResolvePlaceResult } from "./places.types";

@ApiTags("places")
@Controller("maps/places")
@UseGuards(ThrottlerGuard)
export class PlacesController {
  constructor(private readonly placesService: PlacesService) {}

  @Post("resolve")
  @Version("1")
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiOperation({
    summary: "Resolve a typed destination with Google Places (New)",
    description:
      "Optionally uses a nearby coordinate as a location bias and returns one normalized place without exposing the server API key.",
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: "The best matching destination, or null when none is found.",
  })
  @ApiResponse({
    status: HttpStatus.TOO_MANY_REQUESTS,
    description: "Too many paid destination searches from this client.",
  })
  @ApiResponse({
    status: HttpStatus.SERVICE_UNAVAILABLE,
    description: "Destination search is not configured or is unavailable.",
  })
  resolvePlace(@Body() body: ResolvePlaceDto): Promise<ResolvePlaceResult> {
    return this.placesService.resolvePlace(body);
  }
}
