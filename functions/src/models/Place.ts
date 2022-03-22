import { AxiosResponse } from "axios";
import { URLHelper } from "../URLHelper";
import { UserLocation } from "./UserLocation";

export class Place {
    name: string;
    address: string;
    phoneNumber: string;
    icon: string;
    website: string;
    rating: number;
    userRatingsTotal: number;
    priceLevel: number;
    location: UserLocation;
    photos: string[];
    placeId: string;

    constructor(placeJson: AxiosResponse<any, any>, placeId: string) {
        const data = placeJson.data["result"];
        console.log("new place: " + placeId);
        this.placeId = placeId;
        this.name = data["name"];
        this.address = data["formatted_address"];
        this.phoneNumber = data["formatted_phone_number"];
        this.icon = data["icon"];
        this.website = data["website"];
        this.rating = data["rating"];
        this.userRatingsTotal = data["user_ratings_total"];
        this.priceLevel = data["price_level"];
        this.location = new UserLocation(data["geometry"]["location"]["lat"], data["geometry"]["location"]["lng"]);

        this.photos = [];
        const photosJson: any[] = data["photos"];
        photosJson.forEach((element: { [x: string]: string; }) => {
            const photoUrl = URLHelper.getPhotoURL(element["photo_reference"]);
            this.photos.push(photoUrl);
        });
    }

    static getCheapest(places: Place[]): Place {
        let currPrice = 5; // 4 is highest price level from docs
        let cheapestPlace = places[0];
        places.forEach((place) => {
            if (place.priceLevel == null)
                return;
            if (place.priceLevel < currPrice) {
                currPrice = place.priceLevel;
                cheapestPlace = place;
            }
            if (place.priceLevel == currPrice && place.rating > cheapestPlace.rating)
                cheapestPlace = place;
        });
        return cheapestPlace;
    }

    static getBestRating(places: Place[]): Place {
        let currRating = 0; // 1 is lowest rating from docs
        let bestRatedPlace = places[0];
        places.forEach((place) => {
            if (place.rating == null)
                return;
            if (place.rating > currRating) {
                currRating = place.rating;
                bestRatedPlace = place;
            }
            /*if (place.rating == currRating && place.priceLevel < bestRatedPlace.priceLevel)
                bestRatedPlace = place;*/
        });
        return bestRatedPlace;
    }

    static getTop3(places: Place[]) {
        const bestPlaces: Place[] = [];
        for (let i = 0; i < 3; i++) {
            if (this.getBestRating(places) == null)
                return;
            bestPlaces[i] = JSON.parse(JSON.stringify(this.getBestRating(places)));
            const indexToRemove = places.findIndex((place) => place.name == bestPlaces[i].name);
            places.splice(indexToRemove, 1);
        }
        return bestPlaces;
    }
}