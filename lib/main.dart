import 'dart:async';

import 'package:android_id/android_id.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
//import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
//heloo world
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

runApp(const MyApp());
await getPer();
await noti();
getUuid();
}
late StreamSubscription _sub;
late DatabaseReference dbRef;
const notificationChannelId = 'my_foreground';
/////////////////////////////////////////////////////
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();


Future<void> noti()async{
  await Permission.notification.isDenied.then((value) {
    if(value){
      Permission.notification.request();
    }
  });
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
      return;
}
bool isLive =false;
String lat="";
String lang="";
Location location =  Location();

late bool _serviceEnabled;
late PermissionStatus _permissionGranted;
late LocationData _locationData;

String textId="your andriod ID will be shown Here !!!";
String? uuid;
AndroidId id =const AndroidId();

void  getUuid() async {
  uuid = await id.getId();
  textId=uuid!.toUpperCase();
      
}

Future<void> getPer()async{

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
    getUuid();
    dbRef=FirebaseDatabase.instance.ref().child('Loctions');
  }


    String time="";
void  getLoc ()async{

  location.changeNotificationOptions(
  title: 'You Are Live',
  subtitle: 'Tap to return to the App',
  channelName: notificationChannelId,
  onTapBringToFront: true,
  iconName: '@mipmap/ic_launcher',
);
isLive=true;
_sub= location.onLocationChanged.listen((LocationData currentLocation) {
    lat=currentLocation.latitude.toString();
    lang=currentLocation.longitude.toString();
    time=DateTime.now().toString();
    Map<String,String> loctions={
        'lat':lat,
        'lang':lang,
        'time':time,
        'ID':uuid!,
    };
    dbRef.push().set(loctions);
    print("Working");
    setState(() {});
});
}
void calLoc (){
  _sub.cancel();
  setState(() {
    isLive=false;
  });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LOCTION"),
        centerTitle:true,
      ),
    body: Center(child:
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget> [
        Text(textId,style: TextStyle(fontSize: 20),),
        SizedBox(height: 15),
        Text(lang,style: TextStyle(fontSize: 20), ),
        SizedBox(height: 15),
        Text(lat,style: TextStyle(fontSize: 20),),
        SizedBox(height: 15),
        Text(time,style: TextStyle(fontSize: 20),),
        SizedBox(height: 15),
          if (isLive==true)
                ElevatedButton(onPressed: ()async{
                  calLoc();
                  location.enableBackgroundMode(enable: false);
                }, child:  Text("Stop" ,style: TextStyle(fontSize: 24),) ,
                style: ButtonStyle(shape: MaterialStateProperty.all(CircleBorder()),
                padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                backgroundColor: MaterialStateProperty.all(Colors.red),
                )
                )
                else
                ElevatedButton(onPressed:  () async{
                  location.enableBackgroundMode(enable: true);
                    //getPer();
                    getLoc();
                }, child:  Text("Go" ,style: TextStyle(fontSize: 24),) ,
                style: ButtonStyle(shape: MaterialStateProperty.all(CircleBorder()),
                padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                backgroundColor: MaterialStateProperty.all(Colors.green),
                )
                ),
      ],
    )
    ),
    
    );
  }
}