import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateDriverLocationDto {
  @ApiProperty({ example: 12.9716 })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 77.5946 })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;
}
