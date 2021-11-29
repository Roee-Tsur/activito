export class Lobby {
    id: string;
    lobbyCode: string;
    lobbyType: string;

    constructor(id: string, lobbyCode: string, lobbyType: string) {
        this.id = id;
        this.lobbyCode = lobbyCode;
        this.lobbyType = lobbyType;
    }
}
