import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const response = http.getResponse<Response>();
    const request = http.getRequest<Request>();
    const status: number = exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const details = exception instanceof HttpException ? exception.getResponse() : undefined;
    const message = typeof details === 'object' && details !== null && 'message' in details
      ? details.message
      : exception instanceof Error ? exception.message : 'Internal server error';
    if (status >= Number(HttpStatus.INTERNAL_SERVER_ERROR)) this.logger.error(exception);
    response.status(status).json({ success: false, statusCode: status, message, path: request.url, requestId: request.headers['x-request-id'], timestamp: new Date().toISOString() });
  }
}
