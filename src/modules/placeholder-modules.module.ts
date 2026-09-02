import { Module } from '@nestjs/common';
import { createPlaceholderModule } from './scaffolds/placeholder-module.factory';

const moduleRoutes = [
  'addresses', 'drivers', 'providers', 'outstation-rides', 'vehicle-rentals', 'vehicles',
  'room-rentals', 'property-rentals', 'bookings', 'payments', 'wallets', 'notifications',
  'chats', 'reviews', 'favourites', 'coupons', 'uploads', 'admin', 'audit-logs',
];
const placeholderModules = moduleRoutes.map(createPlaceholderModule);

@Module({ imports: placeholderModules })
export class PlaceholderModulesModule {}
