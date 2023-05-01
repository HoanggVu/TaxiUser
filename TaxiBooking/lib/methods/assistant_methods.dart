

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxibooking/global/global.dart';
import 'package:taxibooking/global/map_key.dart';
import 'package:taxibooking/methods/request_assistant.dart';
import 'package:taxibooking/models/directions.dart';
import 'package:taxibooking/models/user_models.dart';
import 'package:http/http.dart' as http;

class AssistantMethods {
  static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(currentUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null){
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  // static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async {
  //   String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
  //   String humanReadableAddress = " ";
  //
  //   var requestResponse = await RequestAssistant.receiveRequest(apiUrl);
  //
  //   if(requestResponse != "Error Occurred. Failed. No response."){
  //     humanReadableAddress = requestResponse["results"][0]["formatted_address"];
  //
  //     Directions userPickUpAddress = Directions();
  //     userPickUpAddress.locationLatitude = position.latitude;
  //     userPickUpAddress.locationLongitude = position.longitude;
  //     userPickUpAddress.locationName = humanReadableAddress;
  //
  //     //Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
  //
  //   }
  //
  //   return humanReadableAddress;
  // }

  static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async {
    String destinationAddress = userDropOffAddress;

    Map<String, String> headNotification = {
      'content-Type': 'application/json',
      'Authorization': cloudMessagingServerToken,
    };

    Map bodyNotification ={
      "body":"Destination Address: \n$destinationAddress.",
      "title":"New Trip Request",
    };

    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };

    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      'to': deviceRegistrationToken,
    };

    var responseNotification = http.post(
      Uri.parse("http://fcm.google.com/fcm/send"),
      headers: headNotification,
      body: jsonEncode(officialNotificationFormat),
    );
  }
}