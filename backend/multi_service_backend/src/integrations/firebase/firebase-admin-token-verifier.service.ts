import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  App,
  AppOptions,
  cert,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import { Auth, DecodedIdToken, getAuth } from 'firebase-admin/auth';
import { ApplicationConfiguration } from '../../config/configuration';

const firebaseAppName = 'multi-service-backend';

@Injectable()
export class FirebaseAdminTokenVerifier {
  private readonly auth: Auth | null;
  private readonly checkRevokedTokens: boolean;

  constructor(
    private readonly configService: ConfigService<
      ApplicationConfiguration,
      true
    >,
  ) {
    const settings = this.configService.get('firebase', { infer: true });
    this.checkRevokedTokens = settings.checkRevokedTokens;
    this.auth = this.hasAdminCredentials(settings)
      ? getAuth(this.getOrCreateApp(settings))
      : null;
  }

  async verify(idToken: string): Promise<DecodedIdToken> {
    if (this.auth == null) {
      throw new ServiceUnavailableException(
        'Firebase authentication is not configured on the backend.',
      );
    }
    try {
      return await this.auth.verifyIdToken(
        idToken,
        this.checkRevokedTokens,
      );
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token.');
    }
  }

  private getOrCreateApp(
    settings: ApplicationConfiguration['firebase'],
  ): App {
    const existing = getApps().find((app) => app.name === firebaseAppName);
    if (existing != null) return existing;

    const options: AppOptions = { projectId: settings.projectId };
    if (settings.clientEmail && settings.privateKey && settings.projectId) {
      options.credential = cert({
        projectId: settings.projectId,
        clientEmail: settings.clientEmail,
        privateKey: settings.privateKey,
      });
    }
    return initializeApp(options, firebaseAppName);
  }

  private hasAdminCredentials(
    settings: ApplicationConfiguration['firebase'],
  ): settings is Required<ApplicationConfiguration['firebase']> {
    return Boolean(
      settings.projectId && settings.clientEmail && settings.privateKey,
    );
  }
}
