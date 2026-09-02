import { PartialType } from '@nestjs/swagger';
import { CreateScaffoldDto } from './create-scaffold.dto';

export class UpdateScaffoldDto extends PartialType(CreateScaffoldDto) {}
