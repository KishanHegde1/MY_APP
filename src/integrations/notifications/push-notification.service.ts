import { Injectable } from '@nestjs/common';
@Injectable()
export class PushNotificationService { send(): Promise<void> { /* TODO: connect the selected push provider. */ return Promise.resolve(); } }
