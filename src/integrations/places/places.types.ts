export interface ResolvedPlace {
  placeId: string;
  name: string;
  formattedAddress: string;
  latitude: number;
  longitude: number;
}

export interface ResolvePlaceResult {
  query: string;
  place: ResolvedPlace | null;
  source: "GOOGLE_PLACES_TEXT_SEARCH";
}
