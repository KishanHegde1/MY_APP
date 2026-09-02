import { Transform, Type } from "class-transformer";
import {
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class PlaceSearchOriginDto {
  @ApiProperty({ example: 12.9716, description: "WGS84 latitude." })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 77.5946, description: "WGS84 longitude." })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;
}

export class ResolvePlaceDto {
  @ApiProperty({
    example: "MG Road, Bengaluru",
    minLength: 3,
    maxLength: 200,
  })
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === "string" ? value.trim() : value,
  )
  @MinLength(3)
  @MaxLength(200)
  query!: string;

  @ApiProperty({
    type: PlaceSearchOriginDto,
    required: false,
    description: "Optional nearby coordinate used to bias Google Places results.",
  })
  @IsOptional()
  @ValidateNested()
  @Type(() => PlaceSearchOriginDto)
  near?: PlaceSearchOriginDto;
}
