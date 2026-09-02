import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';
export class RegisterDto { @IsOptional() @IsEmail() email?: string; @IsOptional() @IsString() phoneNumber?: string; @IsString() @MinLength(8) password!: string; }
