import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateScaffoldDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
