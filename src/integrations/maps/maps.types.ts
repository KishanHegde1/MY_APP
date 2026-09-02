import { RideVehicleType, RoutePointDto } from './dto/compute-routes.dto';

export type ProviderTravelMode = 'DRIVE' | 'TWO_WHEELER';

export interface RouteFareEstimate {
  vehicleType: RideVehicleType;
  currency: 'INR';
  estimatedAmount: number;
  estimatedRange: { minimum: number; maximum: number };
  isEstimate: true;
  pricingModel: 'INDICATIVE_DISTANCE_TIME_V1';
}

export interface ComputedRoute {
  id: string;
  isRecommended: boolean;
  isAlternative: boolean;
  providerLabels: string[];
  distanceMeters: number;
  distanceKilometers: number;
  durationSeconds: number;
  durationMinutes: number;
  staticDurationSeconds: number;
  trafficDelaySeconds: number;
  encodedPolyline: string;
  fareEstimates: RouteFareEstimate[];
}

export interface ComputeRoutesResult {
  origin: RoutePointDto;
  destination: RoutePointDto;
  vehicleType: RideVehicleType;
  providerTravelMode: ProviderTravelMode;
  alternativesRequested: boolean;
  generatedAt: string;
  routes: ComputedRoute[];
  fareDisclaimer: string;
}
