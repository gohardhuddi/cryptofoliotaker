import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs.dart';

const double appBarHeight = 48.0;
const double appBarElevation = 1.0;


bool shortenOn = false;

List marketListData;
Map portfolioMap;
List portfolioDisplay;
Map totalPortfolioStats;

bool isIOS;
String upArrow = "⬆";
String downArrow = "⬇";

int lastUpdate;
Future<Null> getMarketData() async {
  int pages = 5;
  List tempMarketListData = [];

  Future<Null> _pullData(page) async {
    var response = await http.get(
        Uri.encodeFull("https://min-api.cryptocompare.com/data/top/mktcapfull?tsym=USD&limit=100" +
            "&page=" +
            page.toString()),
        headers: {"Accept": "application/json"});

    List rawMarketListData = new JsonDecoder().convert(response.body)["Data"];
    tempMarketListData.addAll(rawMarketListData);
  }

  List<Future> futures = [];
  for (int i = 0; i < pages; i++) {
    futures.add(_pullData(i));
  }
  await Future.wait(futures);

  marketListData = [];
  // Filter out lack of financial data
  for (Map coin in tempMarketListData) {
    if (coin.containsKey("RAW") && coin.containsKey("CoinInfo")) {
      marketListData.add(coin);
    }
  }

  getApplicationDocumentsDirectory().then((Directory directory) async {
    File jsonFile = new File(directory.path + "/marketData.json");
    jsonFile.writeAsStringSync(json.encode(marketListData));
  });
  print("Got new market data.");

  lastUpdate = DateTime.now().millisecondsSinceEpoch;
}
numCommaParse(numString) {
  if (shortenOn) {
    String str = num.parse(numString ?? "0").round().toString().replaceAllMapped(
        new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    List<String> strList = str.split(",");

    if (strList.length > 3) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "B";
    } else if (strList.length > 2) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "M";
    } else {
      return num.parse(numString ?? "0").toString().replaceAllMapped(
          new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    }
  }

  return num.parse(numString ?? "0").toString().replaceAllMapped(
      new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
}

normalizeNum(num input) {
  if (input == null) {
    input = 0;}
  if (input >= 100000) {
    return numCommaParse(input.round().toString());
  } else if (input >= 1000) {
    return numCommaParse(input.toStringAsFixed(2));
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

normalizeNumNoCommas(num input) {
  if (input == null) {
    input = 0;}
  if (input >= 1000) {
    return input.toStringAsFixed(2);
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

class TraceApp extends StatefulWidget {
  TraceApp(this.themeMode, this.darkOLED);
  final themeMode;
  final darkOLED;

  @override
  TraceAppState createState() => new TraceAppState();
}

class TraceAppState extends State<TraceApp> {
  bool darkEnabled;
  String themeMode;
  bool darkOLED;

  void savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("themeMode", themeMode);
    prefs.setBool("shortenOn", shortenOn);
    prefs.setBool("darkOLED", darkOLED);
  }

  toggleTheme() {
    switch (themeMode) {
      case "Automatic":
        themeMode = "Dark";
        break;
      case "Dark":
        themeMode = "Light";
        break;
      case "Light":
        themeMode = "Automatic";
        break;
    }
    handleUpdate();
    savePreferences();
  }

  setDarkEnabled() {
    switch (themeMode) {
      case "Automatic":
        int nowHour = new DateTime.now().hour;
        if (nowHour > 6 && nowHour < 20) {
          darkEnabled = false;
        } else {
          darkEnabled = true;
        }
        break;
      case "Dark":
        darkEnabled = true;
        break;
      case "Light":
        darkEnabled = false;
        break;
    }
    setNavBarColor();
  }

  handleUpdate() {
    setState(() {
      setDarkEnabled();
    });
  }

  switchOLED({state}) {
    setState(() {
      darkOLED = state ?? !darkOLED;
    });
    setNavBarColor();
    savePreferences();
  }

  setNavBarColor() async {
    if (darkEnabled) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor:
              darkOLED ? darkThemeOLED.primaryColor : darkTheme.primaryColor));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: lightTheme.primaryColor));
    }
  }

  final ThemeData lightTheme = new ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    accentColor: Colors.blueAccent[100],
    primaryColor: Colors.white,
    primaryColorLight: Colors.blue[700],
    textSelectionHandleColor: Colors.blue[700],
    dividerColor: Colors.grey[200],
    bottomAppBarColor: Colors.grey[200],
    buttonColor: Colors.blue[700],
    iconTheme: new IconThemeData(color: Colors.white),
    primaryIconTheme: new IconThemeData(color: Colors.black),
    accentIconTheme: new IconThemeData(color: Colors.blue[700]),
    disabledColor: Colors.grey[500],
  );

  final ThemeData darkTheme = new ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    accentColor: Colors.blueAccent[100],
    primaryColor: Color.fromRGBO(50, 50, 57, 1.0),
    primaryColorLight: Colors.blueAccent[100],
    textSelectionHandleColor: Colors.blueAccent[100],
    buttonColor: Colors.blueAccent[100],
    iconTheme: new IconThemeData(color: Colors.white),
    accentIconTheme: new IconThemeData(color: Colors.blueAccent[100]),
    cardColor: Color.fromRGBO(55, 55, 55, 1.0),
    dividerColor: Color.fromRGBO(60, 60, 60, 1.0),
    bottomAppBarColor: Colors.black26,
  );

  final ThemeData darkThemeOLED = new ThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.blueAccent[100],
    primaryColor: Color.fromRGBO(5, 5, 5, 1.0),
    backgroundColor: Colors.black,
    canvasColor: Colors.black,
    primaryColorLight: Colors.blue[300],
    buttonColor: Colors.blueAccent[100],
    accentIconTheme: new IconThemeData(color: Colors.blue[300]),
    cardColor: Color.fromRGBO(16, 16, 16, 1.0),
    dividerColor: Color.fromRGBO(20, 20, 20, 1.0),
    bottomAppBarColor: Color.fromRGBO(19, 19, 19, 1.0),
    dialogBackgroundColor: Colors.black,
    textSelectionHandleColor: Colors.blueAccent[100],
    iconTheme: new IconThemeData(color: Colors.white),
  );

  @override
  void initState() {
    super.initState();
    themeMode = widget.themeMode ?? "Automatic";
    darkOLED = widget.darkOLED ?? false;
    setDarkEnabled();
  }

  @override
  Widget build(BuildContext context) {
    isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      upArrow = "↑";
      downArrow = "↓";
    }

    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      color: darkEnabled
          ? darkOLED ? darkThemeOLED.primaryColor : darkTheme.primaryColor
          : lightTheme.primaryColor,
      title: "Cryptofolio",
      home: new Tabs(
        savePreferences: savePreferences,
        toggleTheme: toggleTheme,
        handleUpdate: handleUpdate,
        darkEnabled: darkEnabled,
        themeMode: themeMode,
        switchOLED: switchOLED,
        darkOLED: darkOLED,
      ),
      theme: darkEnabled ? darkOLED ? darkThemeOLED : darkTheme : lightTheme,
    );
  }
}


class ImportPage extends StatefulWidget {
  @override
  ImportPageState createState() => new ImportPageState();
}

class ImportPageState extends State<ImportPage> {
  TextEditingController _importController = new TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map<String, dynamic> newPortfolioMap;
  Color textColor = Colors.red;
  List validSymbols = [];

  _checkImport(text) {
    try {
      Map<String, dynamic> checkMap = json.decode(text);
      if (checkMap.isEmpty) {
        throw "failed at empty map";
      }
      for (String symbol in checkMap.keys) {
        if (!validSymbols.contains(symbol)) {
          throw "symbol not valid";
        }
      }
      for (List transactions in checkMap.values) {
        if (transactions.isEmpty) {
          throw "failed at emtpy transaction list";
        }
        for (Map transaction in transactions) {
          if ((transaction.keys.toList()..sort()).toString() !=
              ["exchange", "notes", "price_usd", "quantity", "time_epoch"]
                  .toString()) {
            throw "failed formatting check at transaction keys";
          }
          for (String K in transaction.keys) {
            if (K == "quantity" || K == "time_epoch" || K == "price_usd") {
              num.parse(transaction[K].toString());
            }
          }
        }
      }

      newPortfolioMap = checkMap;
      setState(() {
        textColor = Theme.of(context).textTheme.bodyText2.color;
      });
    } catch (e) {
      print("Invalid JSON: $e");
      newPortfolioMap = null;
      setState(() {
        textColor = Colors.red;
      });
    }
  }

  _importPortfolio() {
    showDialog(
        context: context,
        builder: (context) {
          return new AlertDialog(
            title: new Text("Import Portfolio?"),
            content: new Text(
                "This will permanently overwrite current portfolio and transactions."),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () async {
                    portfolioMap = newPortfolioMap;
                    await getApplicationDocumentsDirectory()
                        .then((Directory directory) {
                      File jsonFile =
                      new File(directory.path + "/portfolio.json");
                      jsonFile.writeAsStringSync(json.encode(portfolioMap));
                    });
                    Navigator.of(context).pop();
                    _scaffoldKey.currentState.showSnackBar(
                        new SnackBar(content: new Text("Success!")));
                  },
                  child: new Text("Import")),
              new FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: new Text("Cancel"))
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    marketListData.forEach((coin) {
      validSymbols.add(coin["CoinInfo"]["Name"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new PreferredSize(
          preferredSize: const Size.fromHeight(appBarHeight),
          child: new AppBar(
            titleSpacing: 0.0,
            elevation: appBarElevation,
            title: new Text("Import Portfolio"),
          ),
        ),
        body: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              new Padding(
                padding: EdgeInsets.only(top: 6.0),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(
                    onPressed: () async {
                      String clipText = (await Clipboard.getData('text/plain')).text;
                      _importController.text = clipText;
                      _checkImport(clipText);
                    },
                    child: new Text("Paste",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .apply(color: Theme.of(context).iconTheme.color)),
                  ),
                  new Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                  ),
                  new RaisedButton(
                    onPressed: textColor != Colors.red ? _importPortfolio : null,
                    child: new Text("Import",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .apply(color: Theme.of(context).iconTheme.color)),
                    color: Colors.green,
                  ),
                ],
              ),
              new Container(
                padding: const EdgeInsets.all(10.0),
                child: new TextField(
                  controller: _importController,
                  maxLines: null,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .apply(color: textColor, fontSizeFactor: 1.1),
                  decoration: new InputDecoration(
                      focusedBorder: new OutlineInputBorder(
                          borderSide: new BorderSide(
                              color: Theme.of(context).accentColor,
                              width: 2.0)),
                      border: new OutlineInputBorder(),
                      hintText: "Enter Portfolio JSON"),
                  onChanged: _checkImport,
                ),
              ),
            ],
          ),
        ));
  }
}