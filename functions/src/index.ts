import * as functions from "firebase-functions";
import * as firebaseAdmin from "firebase-admin";
import { Lobby } from "./models/Lobby";
import axios, { } from "axios";
import { Place } from "./models/Place";
import { UserLocation } from "./models/UserLoction";
import { LobbyUser } from "./models/LobbyUser";


firebaseAdmin.initializeApp();

const firestore = firebaseAdmin.firestore();
firestore.settings({ ignoreUndefinedProperties: true })

const maps_api_key = "AIzaSyBI-PzPhUkaozOd4DQKvDSJ6tq1K3S-lww";

// returns code for the created lobby
export const createLobby = functions.region("europe-west1").https.onCall(async (data, context) => {
  functions.logger.info("entered createLobby", { structuredData: true });

  const newLobbyDoc = firestore.collection("lobbies").doc();

  const newLobby = {
    id: newLobbyDoc.id,
    lobbyCode: await generateLobbyCode(),
    lobbyType: data["lobbyType"],
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

exports.addTimeStampToMessage = functions.firestore
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

  const middlePoint = getMiddlePoint(userLocations);
  const locationParameter = middlePoint.latitude.toString() + "%2C" + middlePoint.longitude.toString();
  const config =
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + locationParameter + "&radius=30000&type=restaurant&keyword=cruise&key=" + maps_api_key;

  const requestResults = await axios(config);
  const places: Place[] = [];
  requestResults.data["results"].forEach((result: any) => {
    const placeDetailsURL = "https://maps.googleapis.com/maps/api/place/details/json?fields=name%2Crating%2Cformatted_phone_number%2Cformatted_address%2Cgeometry%2Clocation&place_id=" + result["place_id"] + "&key=" + maps_api_key;
    axios(placeDetailsURL).
      then(placeDetails => { 
        console.log(placeDetails.data);
        places.push(new Place(placeDetails));
      })
      .catch(error => console.error(error));
  });

  return places;
});

function getMiddlePoint(userLocations: UserLocation[]): UserLocation {
  let lat = 0, lng = 0, count = 0;

  userLocations.forEach(userLocation => {
    lng += userLocation.longitude;
    lat += userLocation.latitude;
    count++;
  })

  return { latitude: lat / count, longitude: lng / count } as UserLocation;
}