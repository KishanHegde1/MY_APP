import { Module } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { MapsController } from './maps.controller';
import { MapsService } from './maps.service';

@Module({ controllers: [MapsController], providers: [MapsService, ThrottlerGuard], exports: [MapsService] })
export class MapsModule {}
