import 'dart:async';

import 'package:android_id/android_id.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
  await getPer();
  await noti();
}

late StreamSubscription _sub;

late DatabaseReference dbRef;


//SET NOTIFICATION CHANNEL
const notificationChannelId = 'my_foreground';
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  notificationChannelId, // id
  'MY FOREGROUND SERVICE', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.low, 
);

//GET NOTIFICATION PERMISSION
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> noti() async {
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  return;
}

Location location = Location();

//GET LOACTION PERMISSION
late bool _serviceEnabled;
late PermissionStatus _permissionGranted;

Future<void> getPer() async {
  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }
  }
}

//GET ANDRIOD ID

String textId = "your andriod ID will be shown Here !!!";
String? uuid;
AndroidId id = const AndroidId();

void getUuid() async {
  uuid = await id.getId();
  textId = uuid!.toUpperCase();
}

bool isLive = false;
String lat = "";
String lang = "";
String sped="";
String time = "";



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

// SENDING/UPDATING DATA FUNCION
  void getLoc() async {
    getUuid();
    location.changeNotificationOptions(
      title: 'You Are Live',
      subtitle: 'Tap to return to the App',
      channelName: notificationChannelId,
      onTapBringToFront: true,
      iconName: '@mipmap/ic_launcher',
    );
    isLive = true;
    _sub = location.onLocationChanged.listen((LocationData currentLocation) {
      lat = currentLocation.latitude.toString();
      lang = currentLocation.longitude.toString();
      sped=currentLocation.speed.toString();
      time = DateTime.now().toString();
      print(sped);
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/" + textId);
      Map<String, String> loctions = {
        'lat': lat,
        'lang': lang,
        'time': time,
        'ID': uuid!,
        'sped':sped,
      };
      ref.set(loctions);
      print("Working");
      setState(() {});
    });
  }
//STOP TRACK FUNCTION
  void calLoc() {
    _sub.cancel();
    setState(() {
      isLive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LOCTION"),
        centerTitle: true,
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            textId,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 15),
          Text(
            lang,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 15),
          Text(
            lat,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 15),
          Text(
            time,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 15),
          if (isLive == true)
            ElevatedButton(
                onPressed: () async {
                  calLoc();
                  location.enableBackgroundMode(enable: false);
                },
                child: Text(
                  "Stop",
                  style: TextStyle(fontSize: 24),
                ),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                ))
          else
            ElevatedButton(
                onPressed: () async {
                  location.enableBackgroundMode(enable: true);
                  getLoc();
                },
                child: Text(
                  "Go",
                  style: TextStyle(fontSize: 24),
                ),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(CircleBorder()),
                  padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                )),
        ],
      )),
    );
  }
}
