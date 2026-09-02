import { Body, Controller, Post, Version } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@ApiTags('auth') @Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}
  @Post('login') @Version('1') login(@Body() body: LoginDto) { return this.authService.login(body); }
  @Post('register') @Version('1') register(@Body() body: RegisterDto) { return this.authService.register(body); }
}
