import { ChatMessage } from './chat-message.entity';
import { ChatRoom } from './chat-room.entity';
import { Coupon } from './coupon.entity';
import { DriverProfile } from './driver-profile.entity';
import { Favourite } from './favourite.entity';
import { Notification } from './notification.entity';
import { OutstationRide } from './outstation-ride.entity';
import { PropertyImage } from './property-image.entity';
import { PropertyInquiry } from './property-inquiry.entity';
import { ProviderProfile } from './provider-profile.entity';
import { Review } from './review.entity';
import { RoomBooking } from './room-booking.entity';
import { Room } from './room.entity';
import { Transaction } from './transaction.entity';
import { UserAddress } from './user-address.entity';
import { UserDevice } from './user-device.entity';
import { VehicleDocument } from './vehicle-document.entity';
import { VehicleRental } from './vehicle-rental.entity';
import { WalletTransaction } from './wallet-transaction.entity';
import { Wallet } from './wallet.entity';

export const SCAFFOLD_ENTITIES = [
  UserAddress,
  UserDevice,
  DriverProfile,
  ProviderProfile,
  VehicleDocument,
  PropertyImage,
  Room,
  OutstationRide,
  VehicleRental,
  RoomBooking,
  PropertyInquiry,
  Transaction,
  Wallet,
  WalletTransaction,
  Notification,
  ChatRoom,
  ChatMessage,
  Review,
  Favourite,
  Coupon,
];
