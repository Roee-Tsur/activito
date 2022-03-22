import { Place } from "./Place";

export class Lobby {

    id: string;
    lobbyCode: string;
    lobbyType: string;
    placeRecommendations: Place[];
    numberOfUsers: number;
    lobbyStage: string;

    constructor(lobbyStage:string, id: string, lobbyCode: string, lobbyType: string, placeRecommendations: Place[], numberOfUsers: number) {
        this.lobbyStage = lobbyStage;
        this.id = id;
        this.lobbyCode = lobbyCode;
        this.lobbyType = lobbyType;
        this.placeRecommendations = placeRecommendations;
        this.numberOfUsers = numberOfUsers;
    }

}
