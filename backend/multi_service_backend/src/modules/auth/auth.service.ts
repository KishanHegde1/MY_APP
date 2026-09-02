import { Injectable } from '@nestjs/common';
import { API_PLACEHOLDER_MESSAGE } from '../../common/constants/app.constants';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  login(input: LoginDto) { void input; return { success: true, message: API_PLACEHOLDER_MESSAGE, data: null }; }
  register(input: RegisterDto) { void input; return { success: true, message: API_PLACEHOLDER_MESSAGE, data: null }; }
}
