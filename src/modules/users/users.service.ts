import { Injectable } from '@nestjs/common';
import { API_PLACEHOLDER_MESSAGE } from '../../common/constants/app.constants';

@Injectable()
export class UsersService {
  getProfilePlaceholder() { return { success: true, message: API_PLACEHOLDER_MESSAGE, data: null }; }
}
