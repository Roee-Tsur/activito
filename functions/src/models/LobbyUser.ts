import { UserLocation } from "./UserLocation";

export class LobbyUser {
    id: string;
    activitoUserId: string;
    name: string;
    userLocation: UserLocation;
    isLeader: boolean;
    userNum: number // starts with 0

    constructor(id: string, activitoUserId: string, name: string, location: UserLocation, isLeader: boolean, userNum: number) {
        this.id = id;
        this.activitoUserId = activitoUserId;
        this.name = name;
        this.userLocation = location;
        this.isLeader = isLeader;
        this.userNum = userNum;
    }
}