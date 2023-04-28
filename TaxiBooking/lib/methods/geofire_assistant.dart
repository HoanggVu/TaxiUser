import 'package:taxibooking/models/active_nearby_available_driver.dart';

class GeoFireAssistant{
  static List<ActiveNearByAvailableDrivers> activeNearByAvailableDriversList = [];

  static void deleteOfflineDriverFromList(String driverId){
    int indexNumber = activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverId);

    activeNearByAvailableDriversList.removeAt(indexNumber);
  }

  static void updateActiveNearByAvailableDriversLocation(ActiveNearByAvailableDrivers driverWhoMode){
    activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverWhoMode.driverId);

  }
}