abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const completeProfile = '/complete-profile';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const localRides = '/local-rides';
  static const outstationRides = '/outstation-rides';
  static const vehicleRentals = '/vehicle-rentals';
  static const roomRentals = '/room-rentals';
  static const propertyRentals = '/property-rentals';
  static const bookings = '/bookings';
  static const bookingDetails = '/bookings/details';
  static const payments = '/payments';
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const chat = '/chat';
  static const reviews = '/reviews';
  static const favourites = '/favourites';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addresses = '/profile/addresses';
  static const settings = '/settings';
  static const helpSupport = '/help-support';
  static const providerDashboard = '/provider';
  static const driverDashboard = '/driver';
  static const adminDashboard = '/admin';
  static const notFound = '/not-found';

  static const publicRoutes = <String>{
    splash,
    onboarding,
    login,
    register,
    otp,
    forgotPassword,
  };
}
