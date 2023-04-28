import 'package:flutter/material.dart';
import 'package:taxibooking/models/predicted_places.dart';
import 'package:taxibooking/widgets/progress_dialog.dart';

class PlacesPredictedTileDesign extends StatefulWidget {

  final PredictedPlaces? predictedPlaces;

  PlacesPredictedTileDesign({this.predictedPlaces});

  @override
  State<PlacesPredictedTileDesign> createState() => _PlacesPredictedTileDesignState();
}

class _PlacesPredictedTileDesignState extends State<PlacesPredictedTileDesign> {

  getPlacesDirectionDetails(String? placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
          message: "Setting up Drop-off. Please wait.....",
        )
    );


  }

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return ElevatedButton(
        onPressed: () {

        },
        style: ElevatedButton.styleFrom(
          primary: darkTheme ? Colors.black : Colors.white,
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                Icons.add_location,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),

              SizedBox(height: 10,),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaces!.main_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),

                    Text(
                      widget.predictedPlaces!.secondary_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
}
