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
    isStarted: false,
    placeRecommendations: {}
  } as Lobby;

  newLobbyDoc.set(newLobby);
  return newLobby;
});

// parameter of enteredCode. returns 0 (joined successfully) or 1 (error, didn't join) and a reason(String)
export const joinLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered joinLobby", { structuredData: true });
  const enteredCode = data["enteredCode"] as string;
  const lobbyUser = data["lobbyUser"] as LobbyUser;

  const lobbyDocQuery = await firestore.collection("lobbies").where("lobbyCode", "==", enteredCode).get();
  const lobbyRef = lobbyDocQuery.docs[0];

  firestore.collection("lobbies")
    .doc(lobbyRef.id)
    .collection("users").doc(lobbyUser.id).set(lobbyUser);

  if (lobbyDocQuery.empty)
    return {
      requestStatus: 1,
      reason: "no lobby found for the entered code"
    }
  else
    return {
      requestStatus: 0,
      reason: "joined successfully",
      lobbyId: lobbyRef.id,
      lobbyUserId: lobbyUser.id
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

export const getPlacesRecommendations = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered getPlacesRecommendations", { structuredData: true });
  const lobbyId = data["lobbyId"] as string;

  const users = await firestore.collection("lobbies").doc(lobbyId).collection("users").get();
  const userLocations: UserLocation[] = [];

  users.forEach(doc => {
    userLocations.push(doc.data()["userLocation"])
  });

  //improve radius and check more then 0 places retrived
  const config = URLHelper.getNearbySearchURL(userLocations, 1);
  let requestResults = await axios(config);
  let counter = 1;

  while (requestResults.data["results"].length <= 1) {
    counter += 1;
    const config = URLHelper.getNearbySearchURL(userLocations, counter);
    requestResults = await axios(config);
  }

  const places: Place[] = [];
  const promises: Promise<any>[] = [];

  requestResults.data["results"].forEach((result: any) => {
    const placeDetailsURL = URLHelper.getPlaceDetailsURL(result["place_id"]);
    promises.push(axios(placeDetailsURL).
      then(placeDetails => {
        console.log(placeDetails.data);
        places.push(new Place(placeDetails));
      })
      .catch(error => console.error(error))
    );
  });
  await Promise.all(promises);

  const placeRecommendations = pickBestPlaces(places);

  firestore.collection("lobbies").doc(lobbyId).update({ placeRecommendations: placeRecommendations, isStarted: true });
});

function pickBestPlaces(places: Place[]) {
  if (places == null || places.length == 0)
    return null;

  const placeRecommendations = {
    cheapest: JSON.parse(JSON.stringify(Place.getCheapest(places))),
    bestRating: JSON.parse(JSON.stringify(Place.getBestRating(places)))
  };

  return placeRecommendations;
}