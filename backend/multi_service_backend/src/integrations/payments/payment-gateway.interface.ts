export interface PaymentGateway { createPayment(amount: string, currency: string): Promise<{ providerReference: string }>; }
