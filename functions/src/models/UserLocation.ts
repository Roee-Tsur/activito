export class UserLocation {
    latitude: number;
    longitude: number;

    constructor(lat?: number, lng?: number) {
        this.latitude = 0;
        this.longitude = 0;
        if (lat != null)
            this.latitude = lat;
        if (lng != null)
            this.longitude = lng;
    }

    static toUrlParameter(location: UserLocation): string {
        return location.latitude.toString() + "%2C" + location.longitude.toString();
    }
}