import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String apiKey = await loadApiKey(); // ✅ Load API key dynamically

  runApp(ShelterFinderApp(apiKey: apiKey)); // ✅ Remove `const`
}

// 🔹 Move loadApiKey() outside of any class so it’s accessible in main()
Future<String> loadApiKey() async {
  final jsonString = await rootBundle.loadString('assets/secret.json');
  final jsonMap = json.decode(jsonString);
  return jsonMap['google_maps_api_key'];
}

class ShelterFinderApp extends StatelessWidget {
  final String apiKey;
  const ShelterFinderApp({super.key, required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelter Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(apiKey: apiKey), // 🔹 Pass API key to MapScreen
    );
  }
}

class MapScreen extends StatefulWidget {
  final String apiKey; // ✅ Receive API key

  const MapScreen({super.key, required this.apiKey});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default SF
  Set<Marker> _markers = {}; // Markers for shelters

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Location permission is permanently denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    print("User Location: ${position.latitude}, ${position.longitude}");

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition,
            zoom: 14.0,
          ),
        ),
      );
    } else {
      print("MapController is not yet initialized.");
    }

    _fetchNearbyShelters(position.latitude, position.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _fetchNearbyShelters(double lat, double lng) async {
    final String requestUrl =
        "http://localhost:8080/shelters?lat=$lat&lng=$lng";

    final response = await http.get(Uri.parse(requestUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List results = data['results'];

      Set<Marker> newMarkers = {};

      for (var place in results) {
        double placeLat = place['geometry']['location']['lat'];
        double placeLng = place['geometry']['location']['lng'];
        String name = place['name'];
        String address = place['vicinity'] ?? "No address available";

        newMarkers.add(
          Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(placeLat, placeLng),
            infoWindow: InfoWindow(
              title: name,
              snippet: address,
            ),
          ),
        );
      }

      setState(() {
        _markers = newMarkers;
      });
    } else {
      print("Error fetching places: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shelter Finder')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers, // 🔹 Display fetched markers
      ),
    );
  }
}
