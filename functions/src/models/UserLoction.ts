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

    public toUrlParameter(): string {
        return this.latitude.toString() + "%2C" + this.longitude.toString();
    }
}