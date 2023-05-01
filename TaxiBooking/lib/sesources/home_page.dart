import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxibooking/global/global.dart';
import 'package:taxibooking/global/map_key.dart';
import 'package:taxibooking/methods/assistant_methods.dart';
import 'package:taxibooking/methods/geofire_assistant.dart';
import 'package:taxibooking/models/active_nearby_available_driver.dart';
import 'package:taxibooking/sesources/drawer_page.dart';
import 'package:taxibooking/splashpage/splash_page.dart';
import 'package:taxibooking/widgets/pay_fare_amount_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _address;

  LatLng? pickLocation;
  loc.Location location = loc.Location();

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(16.032951, 108.220983),
    zoom: 14.4746,
  );


  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinatedList = [];
  static const Set<Polyline> polylines = {};

  static const Set<Marker> markersSet = {};
  static const Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";
  String selectedVehicleType = "";
  String driverRideStatus = "Tài Xế Đang Đến";
  StreamSubscription<DatabaseEvent>? stripRidesRequestInfoStreamSubscription;
  List<ActiveNearByAvailableDrivers>? onlineNearByAvailableDriversList = [];
  String userRideRequestStatus = "";

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  final addressController = TextEditingController();
  final newAddressController = TextEditingController();

  DatabaseReference? referenceRideRequest;

  void showSearchingForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
  }

  void showSuggestedRidesContainer() {
    setState(() {
      suggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });
  }
  saveRideRequestInformation(String selectedVehicleType){
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Request").push();
    Map userInformationMap = {
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "userAddress": userModelCurrentInfo!.address,
      "originAddress": "566 Núi Thành",
      "destination": "91 Nguyễn Thiện Kế",
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    stripRidesRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async {
      if(eventSnap.snapshot.value == null){
        return;
      }

      if((eventSnap.snapshot.value as Map)["car_details"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverNam"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }

      if(userRideRequestStatus == "accepted"){
        setState(() {
          driverRideStatus = "Tài Xế Đã Chấp Nhận";
        });
      }

      if(userRideRequestStatus == "arrived"){
        setState(() {
          driverRideStatus = "Tài Xế Đã Đến Nơi";
        });
      }

      if(userRideRequestStatus == "ontrip"){
        setState(() {
          driverRideStatus = "Tài Xế Đang Đến";
        });
      }

      if(userRideRequestStatus == "ended"){
        if((eventSnap.snapshot.value as Map)["fareAmount"] != null){
          double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

          var response = await showDialog(
              context: context,
              builder: (BuildContext context) => PayFareAmountDialog(
                fareAmount: fareAmount,
              )
          );
          if(response == "Cash Paid"){
            if((eventSnap.snapshot.value as Map)["driverId"] != null){
              String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
              //Navigator.push(context, MaterialPageRoute(builder: (c) => RateDriverPage()));

              referenceRideRequest!.onDisconnect();
              stripRidesRequestInfoStreamSubscription!.cancel();
            }
          }
        }
      }

    });

    onlineNearByAvailableDriversList = GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);

  }

  searchNearestOnlineDrivers(String selectedVehicleType) async {
    if(onlineNearByAvailableDriversList?.length != 0){
      referenceRideRequest!.remove();

      Fluttertoast.showToast(msg: "No online nearest Driver Available");
      Fluttertoast.showToast(msg: "Search Again \n Restarting App");

      Future.delayed(Duration(milliseconds: 4000), () {
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c) => SplashPage()));
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList!);

    print("Driver list: " + driversList.toString());

    for(int i = 0; i < driversList.length; i++){
      if(driversList[i]["car_details"]["type"] == selectedVehicleType){
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);
      }
    }
    Fluttertoast.showToast(msg: "Notification sent Successfully");

    showSearchingForDriversContainer();

    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if(eventRideRequestSnapshot.snapshot.value != null){
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUiForAssignedDriverInfo();
        }
      }
    });
  }

  showUiForAssignedDriverInfo(){
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
      suggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async{
    driversList.clear();
    DatabaseReference reference = FirebaseDatabase.instance.ref().child("drivers");

    for(int i = 0; i < onlineNearestDriversList.length; i++){
      await reference.child(onlineNearestDriversList[i].driverId.toString()).once().then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver key information = " + driversList.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;


    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DrawerPage(),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylines,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {

                });
              },
            ),

            Positioned(
              top: 50,
              left: 20,
              child: Container(
                child: GestureDetector(
                  onTap: (){
                    _scaffoldKey.currentState!.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
                    child: Icon(
                      Icons.menu,
                      color: darkTheme ? Colors.black : Colors.lightBlue,
                    ),
                  ),
                ),
              ),
            ),


            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Form(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [

                                            TextField(
                                              decoration: InputDecoration(
                                                hintText: '566 Núi Thành',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                                filled: true,
                                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(
                                                      width: 0,
                                                      style: BorderStyle.none,
                                                    )
                                                ),
                                                prefixIcon: Icon(Icons.location_on, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                              ),

                                              onChanged: (text) => setState(() {
                                                addressController.text = text;
                                              }),
                                            ),

                                            SizedBox(height: 5,),

                                            TextFormField(
                                              decoration: InputDecoration(
                                                hintText: '91 Nguyễn Thiện Kế',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                                filled: true,
                                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(
                                                      width: 0,
                                                      style: BorderStyle.none,
                                                    )
                                                ),
                                                prefixIcon: Icon(Icons.location_on, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
                                              ),

                                              onChanged: (text) => setState(() {
                                                newAddressController.text = text;
                                              }),
                                            ),

                                            SizedBox(height: 5,),

                                            ElevatedButton(
                                                onPressed: () {
                                                  showSuggestedRidesContainer();
                                                },
                                                child: Text(
                                                    "Giá",
                                                  style: TextStyle(
                                                    color: darkTheme ? Colors.black : Colors.white,
                                                  ),
                                                ),
                                              style: ElevatedButton.styleFrom(
                                                primary: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                textStyle: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                )
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),

              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(width: 15,),

                          Text(
                            "566 Núi Thành",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(width: 15,),

                          Text(
                            "91 Nguyễn Thiện Kế",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),
                      
                      Text("CHỌN XE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 20,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: (){
                              setState(() {
                                selectedVehicleType = "Ô Tô";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Ô Tô" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Image.asset("images/car.png", scale: 3,),

                                    SizedBox(height: 8,),
                                    
                                    Text(
                                      "Ô Tô",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Ô Tô" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),

                                    SizedBox(height: 2,),

                                    Text(
                                      "35.000 VND",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: (){
                              setState(() {
                                selectedVehicleType = "Xe Máy";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Xe Máy" ? (darkTheme ? Colors.amber.shade400 : Colors.blue) : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Image.asset("images/car.png", scale: 3,),

                                    SizedBox(height: 8,),

                                    Text(
                                      "Xe Máy",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Xe Máy" ? (darkTheme ? Colors.black : Colors.white) : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),

                                    SizedBox(height: 2,),

                                    Text(
                                      "25.000 VND",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20,),

                      Expanded(
                        child: GestureDetector(
                          onTap: (){
                            if(selectedVehicleType != ""){
                              saveRideRequestInformation(selectedVehicleType);
                            }
                            else{
                              Fluttertoast.showToast(msg: "Please select a vehicle from \n suggested ride.");
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Gửi Yêu Cầu",
                                style: TextStyle(
                                  color: darkTheme ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),

                      SizedBox(height: 10,),

                      Center(
                        child: Text(
                          "Đang Tìm Tài Xế...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      GestureDetector(
                        onTap: () {
                          referenceRideRequest!.remove();
                          setState(() {
                            searchingForDriverContainerHeight = 0;
                            suggestedRidesContainerHeight = 0;
                          });
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: Icon(Icons.close, size: 25,),
                        ),
                      ),

                      SizedBox(height: 15,),

                      Container(
                        width: double.infinity,
                        child: Text(
                          "Thoát",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ] ,
        ),
      ),
    );
  }
}
