import * as functions from "firebase-functions";
import * as firebaseAdmin from "firebase-admin";
import { Lobby } from "./models/Lobby";

firebaseAdmin.initializeApp();

const firestore = firebaseAdmin.firestore();

// returns code for the created lobby
export const createLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered createLobby", { structuredData: true });

  const newLobby = {
    lobbyCode: await generateLobbyCode(),
    users: [] as string[]
  } as Lobby;

  const newLobbyDoc = firestore.collection("lobbies").doc();
  newLobbyDoc.set(newLobby);
  return newLobby;
});

// parameter of enteredCode. returns 0 (joined successfully) or 1 (error, didn't join) and a reason(String)
export const joinLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered joinLobby", { structuredData: true });
  const enteredCode = data["enteredCode"] as string;
  const userName = data["userName"] as string;

  const lobbyDocQuery = await firestore.collection("lobbies").where("lobbyCode", "==", enteredCode).get();
  const lobbyRef = lobbyDocQuery.docs[0];

  firestore.collection("lobbies")
    .doc(lobbyRef.id)
    .update({ users: firebaseAdmin.firestore.FieldValue.arrayUnion(userName) });

  if (lobbyDocQuery.empty)
    return {
      requestStatus: 1,
      reason: "no lobby found for the entered code"
    }
  else
    return {
      requestStatus: 0,
      reason: "joined successfully",
      lobbyId: lobbyRef.id
    }
});

//generate lobby code and makes sure code is unique
async function generateLobbyCode(): Promise<string> {
  let code = "";
  let isUnique = false;
  while (!isUnique) {
    for (let i = 0; i < 6; i++)
      code += String.fromCharCode(Math.floor(Math.random() * (26)) + 65);
    const DBQuery = await firestore.collection("lobbies").where("lobbyCode", "==", code).get();
    isUnique = DBQuery.empty;
  }
  return code;
}
