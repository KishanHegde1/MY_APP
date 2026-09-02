import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../../entities/user.entity';
import { UserRole } from '../../entities/user-role.entity';
import { FirebaseAdminTokenVerifier } from './firebase-admin-token-verifier.service';
import { FirebaseIdentityService } from './firebase-identity.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserRole])],
  providers: [FirebaseAdminTokenVerifier, FirebaseIdentityService],
  exports: [FirebaseIdentityService],
})
export class FirebaseAuthModule {}
