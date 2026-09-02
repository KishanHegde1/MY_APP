import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude, IsOptional, IsString } from 'class-validator';
export class LocationDto { @Type(() => Number) @IsLatitude() latitude!: number; @Type(() => Number) @IsLongitude() longitude!: number; @IsOptional() @IsString() address?: string; }
