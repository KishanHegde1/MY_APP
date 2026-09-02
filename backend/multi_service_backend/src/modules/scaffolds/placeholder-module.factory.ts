import {
  Controller,
  DynamicModule,
  Get,
  Injectable,
  Module,
  Version,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { API_PLACEHOLDER_MESSAGE } from '../../common/constants/app.constants';

export interface PlaceholderModuleResponse {
  success: true;
  message: string;
  data: null;
}

export function createPlaceholderModule(route: string): DynamicModule {
  @Injectable()
  class ScaffoldService {
    getScaffold(): PlaceholderModuleResponse {
      // TODO: Replace this response when the module's business workflow is built.
      return {
        success: true,
        message: API_PLACEHOLDER_MESSAGE,
        data: null,
      };
    }
  }

  @ApiTags(route)
  @Controller(route)
  class ScaffoldController {
    constructor(private readonly scaffoldService: ScaffoldService) {}

    @Get()
    @Version('1')
    getScaffold(): PlaceholderModuleResponse {
      return this.scaffoldService.getScaffold();
    }
  }

  @Module({
    controllers: [ScaffoldController],
    providers: [ScaffoldService],
  })
  class ScaffoldModule {}

  Object.defineProperties(ScaffoldService, {
    name: { value: `${toPascalCase(route)}Service` },
  });
  Object.defineProperties(ScaffoldController, {
    name: { value: `${toPascalCase(route)}Controller` },
  });
  Object.defineProperties(ScaffoldModule, {
    name: { value: `${toPascalCase(route)}Module` },
  });

  return { module: ScaffoldModule };
}

function toPascalCase(value: string): string {
  return value
    .split('-')
    .filter(Boolean)
    .map((part) => `${part.charAt(0).toUpperCase()}${part.slice(1)}`)
    .join('');
}
