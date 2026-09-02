import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { LocalRideRouteSource } from '../../../common/enums/local-ride-route-source.enum';
import { LocalRideVehicleType } from '../../../common/enums/local-ride-vehicle-type.enum';
import { PaymentMethod } from '../../../common/enums/payment-method.enum';

export class LocalRideBookingLocationDto {
  @ApiProperty({ example: 12.9716 })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 77.5946 })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;

  @ApiProperty({ example: 'MG Road, Bengaluru' })
  @IsString()
  @MaxLength(500)
  label!: string;
}

export class CreateLocalRideBookingDto {
  @ApiProperty({ type: LocalRideBookingLocationDto })
  @ValidateNested()
  @Type(() => LocalRideBookingLocationDto)
  pickup!: LocalRideBookingLocationDto;

  @ApiProperty({ type: LocalRideBookingLocationDto })
  @ValidateNested()
  @Type(() => LocalRideBookingLocationDto)
  destination!: LocalRideBookingLocationDto;

  @ApiProperty({ enum: LocalRideVehicleType, example: LocalRideVehicleType.AUTO })
  @IsEnum(LocalRideVehicleType)
  vehicleType!: LocalRideVehicleType;

  @ApiProperty({ example: 'route-1' })
  @IsString()
  @MaxLength(120)
  routeId!: string;

  @ApiProperty({ example: 'Recommended' })
  @IsString()
  @MaxLength(120)
  routeTitle!: string;

  @ApiProperty({ enum: LocalRideRouteSource })
  @IsEnum(LocalRideRouteSource)
  routeSource!: LocalRideRouteSource;

  @ApiProperty({ example: 4.8, minimum: 1, maximum: 100 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(1)
  @Max(100)
  distanceKm!: number;

  @ApiProperty({ example: 19, minimum: 1, maximum: 720 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(720)
  durationMinutes!: number;

  @ApiProperty({ example: 110, minimum: 0, maximum: 100000 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100000)
  estimatedFare!: number;

  @ApiProperty({ enum: PaymentMethod, example: PaymentMethod.CASH })
  @IsEnum(PaymentMethod)
  paymentMethod!: PaymentMethod;

  @ApiPropertyOptional({ description: 'Encoded Google route polyline.' })
  @IsOptional()
  @IsString()
  @MaxLength(500000)
  encodedPolyline?: string;
}
