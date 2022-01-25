import { UserLocation } from "./UserLoction";

export class LobbyUser {
    id: string;
    activitoUserId: string;
    name: string;
    userLocation: UserLocation;
    isLeader: boolean;

    constructor(id: string, activitoUserId: string, name: string, location: UserLocation, isLeader: boolean) {
        this.id = id;
        this.activitoUserId = activitoUserId;
        this.name = name;
        this.userLocation = location;
        this.isLeader = isLeader;
    }
}