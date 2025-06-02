import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String apiKey = await loadApiKey(); // ✅ Load API key dynamically

  runApp(ShelterFinderApp(apiKey: apiKey));
}

// 🔹 Load API Key from `secret.json`
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
        primaryColor: const Color(0xFF005D57),
        scaffoldBackgroundColor: const Color(0xFFFAFAF8),
        fontFamily: 'Roboto', // you can change this if you add fonts
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF005D57),
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF2F2F2),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF005D57)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: RootScreen(apiKey: apiKey),
    );
  }
}

class MapScreen extends StatefulWidget {
  final String apiKey;

  const MapScreen({super.key, required this.apiKey});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default SF
  Set<Marker> _markers = {}; // Shelter markers
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // 🔹 Fetch user's current location
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 14.0),
      ),
    );

    _fetchNearbyShelters(position.latitude, position.longitude);
  }

  // 🔹 Fetch shelters from backend
  Future<void> _fetchNearbyShelters(double lat, double lng) async {
    final String requestUrl =
        "http://localhost:8080/shelters?lat=$lat&lng=$lng";
    final response = await http.get(Uri.parse(requestUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List results = data['results'];

      print("Total shelters received: ${results.length}");

      Set<Marker> newMarkers = {};

      for (var place in results) {
        double placeLat = place['geometry']['location']['lat'];
        double placeLng = place['geometry']['location']['lng'];
        String name = place['name'];
        String address = place['vicinity'] ?? "No address available";
        String placeId = place['place_id'];

        print("Adding Marker: $placeId - $name");

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: LatLng(placeLat, placeLng),
            infoWindow: InfoWindow(title: name, snippet: address),
          ),
        );
      }

      setState(() {
        _markers = newMarkers;
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 12.0),
        ),
      );
    } else {
      print("Error fetching places: ${response.statusCode}");
    }
  }

  // 🔹 Search an address & update map
  Future<void> _searchLocation() async {
    String address = _searchController.text.trim();
    if (address.isEmpty) return;

    final String geocodeUrl = "http://localhost:8080/geocode?address=$address";
    final response = await http.get(Uri.parse(geocodeUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> location = json.decode(response.body);
      double lat = location['lat'];
      double lng = location['lng'];

      setState(() {
        _currentPosition = LatLng(lat, lng);
      });

      _fetchNearbyShelters(lat, lng);
    } else {
      print("Error fetching location for address: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.location_on, size: 20),
            const SizedBox(width: 8),
            const Text('Shelter Finder'),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Enter a city or zip code",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLocation,
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Google Map
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition:
                  CameraPosition(target: _currentPosition, zoom: 12.0),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
            ),
          ),
        ],
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  final String apiKey;
  const RootScreen({super.key, required this.apiKey});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _showMap = false;

  void _continueToMap() {
    setState(() {
      _showMap = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showMap
        ? MapScreen(apiKey: widget.apiKey)
        : OnboardingScreen(onContinue: _continueToMap);
  }
}
