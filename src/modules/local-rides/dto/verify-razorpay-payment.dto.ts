import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class VerifyRazorpayPaymentDto {
  @ApiProperty({ example: 'order_Q9mExampleRazorpay' })
  @IsString()
  @MinLength(3)
  @MaxLength(255)
  razorpayOrderId!: string;

  @ApiProperty({ example: 'pay_Q9mExampleRazorpay' })
  @IsString()
  @MinLength(3)
  @MaxLength(255)
  razorpayPaymentId!: string;

  @ApiProperty({ example: 'signature returned by Razorpay Checkout' })
  @IsString()
  @MinLength(32)
  @MaxLength(255)
  razorpaySignature!: string;
}
