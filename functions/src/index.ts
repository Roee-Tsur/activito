import * as functions from "firebase-functions";
import * as firebaseAdmin from "firebase-admin";
import { Lobby } from "./models/Lobby";
import axios from "axios";
import { Place } from "./models/Place";
import { UserLocation } from "./models/UserLocation";
import { LobbyUser } from "./models/LobbyUser";
import { URLHelper } from "./URLHelper";


firebaseAdmin.initializeApp();

const firestore = firebaseAdmin.firestore();
firestore.settings({ ignoreUndefinedProperties: true })

// returns code for the created lobby
export const createLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered createLobby", { structuredData: true });

  const newLobbyDoc = firestore.collection("lobbies").doc();

  const newLobby = {
    id: newLobbyDoc.id,
    lobbyCode: await generateLobbyCode(),
    lobbyType: data["lobbyType"],
    lobbyStage: "open",
    placeRecommendations: [],
    numberOfUsers: 0,
    winningPlaceIndex: -1
  } as Lobby;

  newLobbyDoc.set(newLobby);
  newLobbyDoc.collection("individualFields").doc("initialVotesCount").set({ initialVotesCount: 0 });
  newLobbyDoc.collection("individualFields").doc("finalVotes").set({ 0: 0, 1: 0, 2: 0 }); //number of fields need to match place recommendations count
  return newLobby;
});

// parameter of enteredCode. returns 0 (joined successfully) or 1 (error, didn't join) and a reason(String)
export const joinLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered joinLobby", { structuredData: true });
  const enteredCode = data["enteredCode"] as string;
  const lobbyUser = data["lobbyUser"] as LobbyUser;

  const lobbyDocQuery = await firestore.collection("lobbies").where("lobbyCode", "==", enteredCode).get();
  const lobbyRef = lobbyDocQuery.docs[0].ref;
  const lobby = lobbyDocQuery.docs[0].data() as Lobby;

  if (lobbyDocQuery.empty)
    return {
      requestStatus: 1,
      reason: "no lobby found for the entered code"
    };
  if (lobby.lobbyStage == "voting")
    return {
      requestStatus: 1,
      reason: "lobby already in proggress"
    }
  else {
    lobbyUser.userNum = lobby.numberOfUsers;
    lobby.numberOfUsers++;

    lobbyRef
      .collection("users").doc(lobbyUser.id).set(lobbyUser);
    lobbyRef.update({ numberOfUsers: lobby.numberOfUsers });

    return {
      requestStatus: 0,
      reason: "joined successfully",
      lobbyId: lobby.id,
      lobbyUserId: lobbyUser.id
    }
  }
});

exports.addTimeStampToMessage = functions.region("europe-west1").firestore
  .document("lobbies/{lobbyId}/messages/{messageId}")
  .onCreate((snap, context) => {
    const lobbyId = context.params.lobbyId;
    const messageId = context.params.messageId;
    const timestamp = firebaseAdmin.firestore.FieldValue.serverTimestamp();
    firestore.collection("lobbies").doc(lobbyId).collection("messages").doc(messageId).update({ timestamp: timestamp })
  });

exports.checkVotesCount = functions.region("europe-west1").firestore
  .document("lobbies/{lobbyId}/individualFields/initialVotesCount")
  .onUpdate((snap, context) => {
    const numberOfUsers = snap.after.data().numberOfUsers;
    const numberOfInitialVotes = snap.after.data().initialVotesCount;
    if (numberOfUsers <= numberOfInitialVotes) { //true when everybody sent initial vote
      const lobbyId = context.params.lobbyId;
      const timestamp = firebaseAdmin.firestore.FieldValue.serverTimestamp();

      firestore.collection("lobbies").doc(lobbyId).update({ lobbyStage: "final votes", startCountDownTime: timestamp }); //adds time for client side to show timer
    }
  });

exports.checkFinalVotes = functions.region("europe-west1").firestore
  .document("lobbies/{lobbyId}/individualFields/finalVotes")
  .onUpdate((snap, context) => {
    const numberOfUsers = snap.after.data().numberOfUsers;
    const docData = snap.after.data();
    const numberOfVotes = docData["0"] + docData["1"] + docData["2"];
    if (numberOfUsers <= numberOfVotes) { //true when all the final votes are in
      const lobbyId = context.params.lobbyId;

      const places = [docData["0"], docData["1"], docData["2"]] as number[];
      const winningPlaceIndex = places.indexOf(Math.max(docData["0"], docData["1"], docData["2"]));

      firestore.collection("lobbies").doc(lobbyId).update({ lobbyStage: "done", winningPlaceIndex: winningPlaceIndex }); //adds time for client side to show timer
    }
  });

export const getPlacesRecommendations = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered getPlacesRecommendations", { structuredData: true });
  const lobbyId = data["lobbyId"] as string;

  //update lobby stage to: looking for places
  firestore.collection("lobbies").doc(lobbyId).update({ lobbyStage: "finding places" });

  const users = await firestore.collection("lobbies").doc(lobbyId).collection("users").get();
  const userLocations: UserLocation[] = [];

  //adds total number of users to initialVotesCount to check when to end voting
  firestore.collection("lobbies").doc(lobbyId).collection("individualFields").doc("initialVotesCount").update({ numberOfUsers: users.size })
  firestore.collection("lobbies").doc(lobbyId).collection("individualFields").doc("finalVotes").update({ numberOfUsers: users.size })

  users.forEach(doc => {
    userLocations.push(doc.data()["userLocation"])
  });

  const config = URLHelper.getNearbySearchURL(userLocations, 1);
  console.log("nearby search url: " + config);
  const requestResults = await axios(config);


  /*let counter = 1;

  while (requestResults.data["results"].length <= 1) {
    console.log("looking for places attempt number: " + counter);
    counter += 1;
    const config = URLHelper.getNearbySearchURL(userLocations, counter);
    requestResults = await axios(config);
  }*/

  const places: Place[] = [];
  const promises: Promise<any>[] = [];

  requestResults.data["results"].forEach((result: any) => {
    const placeDetailsURL = URLHelper.getPlaceDetailsURL(result["place_id"]);
    promises.push(axios(placeDetailsURL).
      then(placeDetails => {
        places.push(new Place(placeDetails, result["place_id"]));
      })
      .catch(error => console.error(error))
    );
  });
  await Promise.all(promises);

  const placeRecommendations = pickBestPlaces(places);

  firestore.collection("lobbies").doc(lobbyId).update({ placeRecommendations: placeRecommendations, lobbyStage: "voting" });
});

export const userExitLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered userExitLobby", { structuredData: true });
  const lobbyId = data["lobbyId"] as string;
  const userId = data["userId"] as string;

  const lobbyRef = firestore.collection("lobbies").doc(lobbyId);

  lobbyRef.collection("users").doc(userId).delete();
  await lobbyRef.update({ numberOfUsers: firebaseAdmin.firestore.FieldValue.increment(-1) })
  lobbyRef.get().then((lobbySnap) => {
    if (lobbySnap?.data()?.numberOfUsers < 1) {
      lobbyRef.collection("individualFields").listDocuments().then(docs => { docs.forEach(doc => { doc.delete(); }) });
      lobbyRef.delete();
    }
  });
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

//returns 3 places with highest ratings
function pickBestPlaces(places: Place[]) {
  if (places == null || places.length == 0)
    return null;

  const placeRecommendations = Place.getTop3(places);

  return placeRecommendations;
}