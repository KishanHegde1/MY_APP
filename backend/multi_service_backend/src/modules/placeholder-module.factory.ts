import { Controller, Get, Injectable, Module, Type, Version } from '@nestjs/common';
import { API_PLACEHOLDER_MESSAGE } from '../common/constants/app.constants';
export interface PlaceholderResponse { success: true; message: string; data: null; }
export const createPlaceholderModule = (route: string): Type<unknown> => {
  @Injectable() class PlaceholderService { getStatus(): PlaceholderResponse { return { success: true, message: API_PLACEHOLDER_MESSAGE, data: null }; } }
  @Controller(route) class PlaceholderController { constructor(private readonly service: PlaceholderService) {} @Get() @Version('1') getStatus(): PlaceholderResponse { return this.service.getStatus(); } }
  @Module({ controllers: [PlaceholderController], providers: [PlaceholderService] }) class DynamicPlaceholderModule {}
  return DynamicPlaceholderModule;
};
