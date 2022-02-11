import { Place } from "./Place";

export class Lobby {
    isStarted: boolean;
    id: string;
    lobbyCode: string;
    lobbyType: string;
    placeRecommendations: Place[];

    constructor(isStarted: boolean, id: string, lobbyCode: string, lobbyType: string, placeRecommendations: Place[]) {
        this.isStarted = isStarted;
        this.id = id;
        this.lobbyCode = lobbyCode;
        this.lobbyType = lobbyType;
        this.placeRecommendations = placeRecommendations;
    }
}
