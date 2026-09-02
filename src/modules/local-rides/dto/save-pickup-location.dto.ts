import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsLatitude,
  IsLongitude,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PickupLocationSource } from '../../../entities/user-pickup-location.entity';

export class SavePickupLocationDto {
  @ApiProperty({ example: 12.9715987, description: 'WGS84 latitude.' })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 77.594566, description: 'WGS84 longitude.' })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;

  @ApiProperty({
    example: 'MG Road, Bengaluru, Karnataka 560001, India',
    minLength: 3,
    maxLength: 500,
  })
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @MinLength(3)
  @MaxLength(500)
  formattedAddress!: string;

  @ApiProperty({
    enum: [...Object.values(PickupLocationSource), 'MAP_PIN'],
    example: 'MAP_PIN',
    description: 'MAP_PIN is accepted from mobile clients and stored as PIN.',
  })
  @Transform(({ value }: { value: unknown }) =>
    value === 'MAP_PIN' ? PickupLocationSource.PIN : value,
  )
  @IsEnum(PickupLocationSource)
  source!: PickupLocationSource;
}
