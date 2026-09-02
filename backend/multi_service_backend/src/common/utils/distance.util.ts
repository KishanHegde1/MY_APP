const earthRadiusKm = 6371;
const radians = (degrees: number): number => (degrees * Math.PI) / 180;
export const calculateDistanceInKm = (from: { latitude: number; longitude: number }, to: { latitude: number; longitude: number }): number => {
  const latitudeDelta = radians(to.latitude - from.latitude); const longitudeDelta = radians(to.longitude - from.longitude);
  const a = Math.sin(latitudeDelta / 2) ** 2 + Math.cos(radians(from.latitude)) * Math.cos(radians(to.latitude)) * Math.sin(longitudeDelta / 2) ** 2;
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};
