import { Module } from "@nestjs/common";
import { MapsModule } from "./maps/maps.module";
import { PlacesModule } from "./places/places.module";
import { PaymentGatewayModule } from "./payments/payment-gateway.module";
import { PushNotificationModule } from "./notifications/push-notification.module";
import { StorageModule } from "./storage/storage.module";
import { SmsModule } from "./sms/sms.module";

@Module({
  imports: [
    MapsModule,
    PlacesModule,
    PaymentGatewayModule,
    PushNotificationModule,
    StorageModule,
    SmsModule,
  ],
})
export class IntegrationModulesModule {}
