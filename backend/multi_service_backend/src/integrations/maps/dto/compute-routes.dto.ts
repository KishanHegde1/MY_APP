import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsLatitude, IsLongitude, IsOptional, ValidateNested } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum RideVehicleType {
  bike = 'BIKE',
  auto = 'AUTO',
  car = 'CAR',
}

export class RoutePointDto {
  @ApiProperty({ example: 12.9716, description: 'WGS84 latitude.' })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 77.5946, description: 'WGS84 longitude.' })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;
}

export class ComputeRoutesDto {
  @ApiProperty({ type: RoutePointDto })
  @ValidateNested()
  @Type(() => RoutePointDto)
  origin!: RoutePointDto;

  @ApiProperty({ type: RoutePointDto })
  @ValidateNested()
  @Type(() => RoutePointDto)
  destination!: RoutePointDto;

  @ApiPropertyOptional({
    default: true,
    description: 'Ask Google Routes for alternate routes in addition to the recommended route.',
  })
  @IsOptional()
  @IsBoolean()
  alternatives?: boolean;

  @ApiPropertyOptional({
    enum: RideVehicleType,
    default: RideVehicleType.car,
    description: 'Vehicle used for route geometry, ETA, and this route\'s fare estimate.',
  })
  @IsOptional()
  @IsEnum(RideVehicleType)
  vehicleType?: RideVehicleType;
}
