import {
  Injectable,
  InternalServerErrorException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import { ApplicationConfiguration } from '../../config/configuration';

interface RazorpayOrderResponse {
  id: string;
  amount: number;
  currency: string;
}

@Injectable()
export class RazorpayGatewayService {
  constructor(
    private readonly config: ConfigService<ApplicationConfiguration, true>,
  ) {}

  isConfigured(): boolean {
    const payment = this.config.get('payments', { infer: true });
    return Boolean(
      payment.provider === 'razorpay' &&
        payment.razorpayKeyId &&
        payment.razorpayKeySecret,
    );
  }

  keyId(): string {
    return this.credentials().keyId;
  }

  async createOrder(input: {
    amountInPaise: number;
    receipt: string;
    bookingId: string;
  }): Promise<RazorpayOrderResponse> {
    const credentials = this.credentials();
    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(
          `${credentials.keyId}:${credentials.keySecret}`,
        ).toString('base64')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: input.amountInPaise,
        currency: 'INR',
        receipt: input.receipt,
        notes: { booking_id: input.bookingId },
      }),
    });
    const body = (await response.json().catch(() => null)) as
      | RazorpayOrderResponse
      | { error?: { description?: string } }
      | null;
    if (!response.ok || body == null || !('id' in body)) {
      throw new InternalServerErrorException(
        body != null && 'error' in body && body.error?.description
          ? `Razorpay order creation failed: ${body.error.description}`
          : 'Razorpay order creation failed.',
      );
    }
    return body;
  }

  verifySignature(input: {
    orderId: string;
    paymentId: string;
    signature: string;
  }): boolean {
    const { keySecret } = this.credentials();
    const expected = createHmac('sha256', keySecret)
      .update(`${input.orderId}|${input.paymentId}`)
      .digest('hex');
    const received = Buffer.from(input.signature, 'utf8');
    const expectedBuffer = Buffer.from(expected, 'utf8');
    return (
      received.length === expectedBuffer.length &&
      timingSafeEqual(received, expectedBuffer)
    );
  }

  private credentials(): { keyId: string; keySecret: string } {
    const payment = this.config.get('payments', { infer: true });
    if (
      payment.provider !== 'razorpay' ||
      !payment.razorpayKeyId ||
      !payment.razorpayKeySecret
    ) {
      throw new ServiceUnavailableException(
        'Razorpay is not configured for this environment.',
      );
    }
    return {
      keyId: payment.razorpayKeyId,
      keySecret: payment.razorpayKeySecret,
    };
  }
}
