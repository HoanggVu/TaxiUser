import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxibooking/models/user_models.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;


String cloudMessagingServerToken = "key=AAAA9KQv5vM:APA91bEvQUqf-UJ2D9GgGmU6pIhvSb1V5sJ3mFbn8-agRrTeNXmRuFvWC21RXFa-g_7AuvJoSIbs3OEVOdbSNzuGUaFWbxeLivfDJmmqCbsmntDHpIoIB86l17zUA6ivZgpzUpwCpnfB";
UserModel? userModelCurrentInfo;
String userDropOffAddress = "566 Núi Thành";
String driverCarDetails = "";
String driverName = "";
String driverPhone = "";

double countRatingStars = 0.0;
String titleStarsRating = "";

List driversList = [];