import { AxiosResponse } from "axios";
import { UserLocation } from "./UserLoction";

export class Place {
    name: string;
    address: string;
    phoneNumber: string;
    location: UserLocation;

    constructor(placeJson: AxiosResponse<any, any>) {
        const data = placeJson["data"];
        console.log("location: " + data["geometry"]["location"].toString());
        this.name = data["name"];
        this.address = data["formatted_address"];
        this.phoneNumber = data["formatted_phone_number"];
        this.location = new UserLocation(data["geometry"]["location"]["lat"], data["geometry"]["location"]["lng"]);
    }
}