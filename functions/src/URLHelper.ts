import { UserLocation } from "./models/UserLocation";

export class URLHelper {
    static maps_api_key = "AIzaSyBI-PzPhUkaozOd4DQKvDSJ6tq1K3S-lww";

    static getPhotoURL(photoReference: string) {
        return "https://maps.googleapis.com/maps/api/place/photo&photo_reference="
            .concat(photoReference, "&", this.maps_api_key);
    }

    static getPlaceDetailsURL(placeId: string,) {
        return "https://maps.googleapis.com/maps/api/place/details/json?fields="
            .concat("name",
                "%2Crating",
                "%2Cprice_level",
                "%2Cformatted_phone_number",
                "%2Cformatted_address",
                "%2Cgeometry",
                "%2Cicon",
                "%2Cwebsite",
                "%2Cuser_ratings_total",
                "%2Cprice_level",
                "%2Cphotos")
            .concat("&place_id=", placeId,
                "&key=", this.maps_api_key);
    }

    static getNearbySearchURL(userLocations: UserLocation[], multiplyer: number) {
        const middlePoint = this.getMiddlePoint(userLocations);
        let radius = this.getRadios(userLocations, middlePoint);
        
        // for development stage
        if (userLocations.length == 1) {
            radius = 15000;
        }

        return "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="
            .concat(UserLocation.toUrlParameter(middlePoint))
            .concat("&radius=", (radius * multiplyer).toString())
            .concat("&opennow=true")
            .concat("&type=restaurant")
            .concat("&key=", this.maps_api_key);
    }

    static getMiddlePoint(userLocations: UserLocation[]): UserLocation {
        let lat = 0, lng = 0, count = 0;

        userLocations.forEach(userLocation => {
            lng += userLocation.longitude;
            lat += userLocation.latitude;
            count++;
        })

        return { latitude: lat / count, longitude: lng / count } as UserLocation;
    }

    static getDistanceBetween2Locations(location1: UserLocation, location2: UserLocation) {
        const lat1 = location1.latitude;
        const lat2 = location2.latitude;
        const lon1 = location1.longitude;
        const lon2 = location2.longitude;

        const R = 6371000; // Radius of the earth in meters
        const dLat = this.deg2rad(lat2 - lat1);  // deg2rad below
        const dLon = this.deg2rad(lon2 - lon1);
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2)
            ;
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const d = R * c; // Distance in meters
        return d;
    }

    static deg2rad(deg: number) {
        return deg * (Math.PI / 180)
    }

    // returns shortest radios
    static getRadios(userLocations: UserLocation[], middleLocation: UserLocation) {
        let closestLocation = userLocations[0];
        let shortestRadios = this.getDistanceBetween2Locations(middleLocation, closestLocation);
        userLocations.forEach((userLocation) => {
            const newRadios = this.getDistanceBetween2Locations(middleLocation, userLocation);
            if (newRadios < shortestRadios) {
                shortestRadios = newRadios;
                closestLocation = userLocation;
            }
        });
        return shortestRadios;
    }
}