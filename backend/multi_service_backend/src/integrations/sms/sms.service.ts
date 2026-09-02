import { Injectable } from '@nestjs/common';
@Injectable()
export class SmsService { sendOtp(): Promise<void> { /* TODO: connect the selected SMS provider. */ return Promise.resolve(); } }
