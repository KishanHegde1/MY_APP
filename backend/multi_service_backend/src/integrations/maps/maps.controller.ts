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
import { ComputeRoutesDto } from "./dto/compute-routes.dto";
import { MapsService } from "./maps.service";
import { ComputeRoutesResult } from "./maps.types";

@ApiTags("maps")
@Controller("maps")
@UseGuards(ThrottlerGuard)
export class MapsController {
  constructor(private readonly mapsService: MapsService) {}

  @Post("routes")
  @Version("1")
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @ApiOperation({
    summary: "Compute local-ride routes within the configured distance range",
    description:
      "Returns only Google route alternatives whose road distance is between LOCAL_RIDE_MIN_DISTANCE_KM and LOCAL_RIDE_MAX_DISTANCE_KM, inclusive.",
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: "Normalized routes with indicative fare estimates.",
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description:
      "Invalid coordinates, a route below the configured minimum, or a route beyond the configured maximum.",
  })
  @ApiResponse({
    status: HttpStatus.TOO_MANY_REQUESTS,
    description: "Too many route requests from this client.",
  })
  @ApiResponse({
    status: HttpStatus.SERVICE_UNAVAILABLE,
    description: "Route planning is not configured or temporarily unavailable.",
  })
  computeRoutes(@Body() body: ComputeRoutesDto): Promise<ComputeRoutesResult> {
    return this.mapsService.computeRoutes(body);
  }
}
