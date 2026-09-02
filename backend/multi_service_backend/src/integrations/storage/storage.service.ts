import { Injectable } from '@nestjs/common';
@Injectable()
export class StorageService { upload(): Promise<null> { return Promise.resolve(null); } }
