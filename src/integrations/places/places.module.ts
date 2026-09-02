import { Module } from "@nestjs/common";
import { ThrottlerGuard } from "@nestjs/throttler";
import { PlacesController } from "./places.controller";
import { PlacesService } from "./places.service";

@Module({
  controllers: [PlacesController],
  providers: [PlacesService, ThrottlerGuard],
  exports: [PlacesService],
})
export class PlacesModule {}
