import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:only_web/shopsModel.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBcA4klUGzIamW7PC-nERoW9zcEVCWjLfg",
            authDomain: "location-e5cc0.firebaseapp.com",
            projectId: "location-e5cc0",
            storageBucket: "location-e5cc0.appspot.com",
            messagingSenderId: "132021888954",
            appId: "1:132021888954:web:9a8e12d10f6b4b1c93df83"
        )
    );
    print("Initialize is OK");
  } catch(e) {
    print("Initialize failed: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard("id_here"),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String user_id;

  Dashboard(this.user_id);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late loc.Location location;
  late GoogleMapController _controller;
  bool _added = false;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  Set<Marker> _markers = {};
  //late Future<List<Shop>> shoplist;


  @override
  void initState() {
    super.initState();
    fetchData();
    location = loc.Location();
    WidgetsBinding.instance!.addObserver(this);
    _initLocationTracking();
    //shoplist = fetchShops();
  }

  void _initLocationTracking() {
    _locationSubscription = location.onLocationChanged.listen(
          (loc.LocationData currentLocation) {
        if (_added) {
          _updateMarkerPosition(
              currentLocation.latitude!, currentLocation.longitude!);
        }
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  void _updateMarkerPosition(double latitude, double longitude) async {
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 14.47,
        ),
      ),
    );
  }

  Future<QuerySnapshot> fetchData() async {
    return await FirebaseFirestore.instance.collection('location').get();
  }

  Future<List<Shop>> fetchShops() async {
    final response = await get(Uri.parse(
        'https://g77e7c85ff59092-db17lrv.adb.ap-singapore-1.oraclecloudapps.com/ords/metaxperts/shoploc/get/'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      var shopJson = jsonDecode(response.body);
      var shopsData = shopJson['items'];
      return shopsData.map<Shop>((shop) => Shop.fromJson(shop)).toList();
    } else {
      throw Exception('Failed to load shops');
    }
  }

  Future<Set<Marker>> _createMarkersFromData(QuerySnapshot snapshot) async {
    var futures = snapshot.docs.map((doc) async {
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(doc['latitude'], doc['longitude']),
        icon: await CustomIcon(symbol: doc['name'], color: Colors.blue)
            .toBitmapDescriptor(
            logicalSize: const Size(150, 150), imageSize: const Size(150, 150)
        ),
        infoWindow: InfoWindow(title: doc['name']),
      );
    });

    var markers = await Future.wait(futures);
    return markers.toSet();
  }

  Set<Marker> shopsMarkers(List<Shop> shops) {
    return shops.where((shop) =>
    shop.latitude != null && shop.longitude != null).map((shop) =>
        Marker(
            markerId: MarkerId(shop.name!),
            position: LatLng(shop.latitude!, shop.longitude!),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: shop.name.toString())
        )).toSet();
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('location').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        try {
          _createMarkersFromData(snapshot.data!).then((markers) {
            setState(() {
              _markers = {...markers};
            });
          });
        } catch (e) {
          print("W100 ${e.toString()}");
        }

        return GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          markers: _markers,
          initialCameraPosition: CameraPosition(
            target: _markers.first.position,
            zoom: 13,
          ),
          // other properties...
        );
      },
    );
  }
}


class CustomIcon extends StatelessWidget {
  final String symbol;
  final Color color;

  const CustomIcon({
    Key? key,
    required this.symbol,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.location_pin,
          color: color,
          size: 65,
        ),
        Positioned(
          height: 30,
          left: 8,
          top: 10,
          child: Container(
            width: 50,
            height: 50,
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
            ),
          ),
        ),
        Positioned(
          bottom: 45,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontStyle: FontStyle.normal,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
