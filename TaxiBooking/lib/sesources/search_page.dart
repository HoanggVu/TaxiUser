import 'package:flutter/material.dart';
import 'package:taxibooking/models/predicted_places.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  List<PredictedPlaces> placesPredictedList = [];

  searchLocation(String inputText) async {

  }


  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
          leading: GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: darkTheme ? Colors.black : Colors.white,),
          ),
          title: Text(
            "Search",
            style: TextStyle(color: darkTheme ? Colors.black : Colors.white),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    )
                  )
                ],
              ),

              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.adjust_sharp, color:  darkTheme ? Colors.black : Colors.white,),

                        SizedBox(height: 10,),
                        
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              onChanged: (value){
                                searchLocation(value);
                              },
                              decoration: InputDecoration(
                                hintText: "Search...",
                                fillColor: darkTheme ? Colors.black : Colors.white54,
                                filled: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  left: 11,
                                  top: 8,
                                  bottom: 8,
                                )
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            // (placesPredictedList.length > 0)
            // ? Expanded(
            //   child: ListView.separated(
            //     itemCount: placesPredictedList.length,
            //     physics: ClampingScrollPhysics(),
            //     itemBuilder: (context, index){
            //
            //     },
            //   ),
            //)

          ],
        ),
      ),
    );
  }
}
