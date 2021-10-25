export class Lobby {
    lobbyCode: string;
    users: string[];

    constructor(lobbyCode: string, users: string[]) {
        this.lobbyCode = lobbyCode;
        this.users = users;
    }
}
