import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<{ method: string; originalUrl: string; headers: Record<string, string | undefined> }>();
    const start = Date.now();
    return next.handle().pipe(tap(() => this.logger.log(`${request.method} ${request.originalUrl} ${Date.now() - start}ms requestId=${request.headers['x-request-id'] ?? 'n/a'}`)));
  }
}
