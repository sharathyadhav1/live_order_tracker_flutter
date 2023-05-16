import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_mao/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


import 'components/rider_info.dart';

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();
  PolylinePoints polylinePoints = PolylinePoints();

  //drawn routes on the map
  final Set<Polyline> _polylines = <Polyline>{};
  List<LatLng> polylineCoordinates = [];

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLicationIcon = BitmapDescriptor.defaultMarker;

  // Location
  LocationData? currentLocation;

  static const LatLng sourceLocation = LatLng(25.2548,55.4009); //etisalat
  static const LatLng destination = LatLng(25.2733, 55.3695);// al nahada
  Location location = Location();

  CameraPosition? initialCameraPosition;

  void initialLocation() async {
    location.getLocation().then(
      (currentLoc) {
        currentLocation = currentLoc;
        initialCameraPosition = CameraPosition(
          target: LatLng(currentLoc.latitude!, currentLoc.longitude!),
          zoom: 14.5,
          tilt: 59,
          bearing: -70,
        );
        location.onLocationChanged.listen((LocationData newLoc) async {
          currentLocation = newLoc;

          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(newLoc.latitude!, newLoc.longitude!),
                zoom: 14.5,
                tilt: 59,
                bearing: -70,
              ),
            ),
          );
          setState(() {});
        });
      },
    );
  }

  void getPolyPoints() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      optimizeWaypoints: true,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        },
      );
      setState(
        () {
          _polylines.add(
            Polyline(
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              geodesic: true,
              polylineId: const PolylineId("line"),
              width: 6,
              color: primaryColor,
              points: polylineCoordinates,
            ),
          );
        },
      );
    }
  }

  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(24, 24)),
            'assets/Pin_source.png')
        .then(
      (value) {
        sourceIcon = value;
      },
    );
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), 'assets/Pin_destination.png')
        .then(
      (value) {
        destinationIcon = value;
      },
    );
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), 'assets/car.png')
        .then(
      (value) {
        currentLicationIcon = value;
      },
    );
  }

  @override
  void initState() {
    // FirebaseCrashlytics.instance.crash();

    initialLocation();
    getPolyPoints();
    setSourceAndDestinationIcons();
    FirebaseAnalytics.instance.logEvent(name: 'awr app start');
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Awr tracking Demo",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocation == null
          ? const Center(child: Text("Loading..."))
          : Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: GoogleMap(
                      zoomControlsEnabled: true,
                      initialCameraPosition: initialCameraPosition!,
                      polylines: _polylines,
                      markers: {
                        Marker(
                          markerId: const MarkerId("currentLocation"),
                          icon: currentLicationIcon,
                          position: LatLng(currentLocation!.latitude!,
                              currentLocation!.longitude!),
                        ),
                        Marker(
                          markerId: const MarkerId("source"),
                          icon: sourceIcon,
                          position: sourceLocation,
                        ),
                        Marker(
                          markerId: const MarkerId("destination"),

                          position: destination,
                        ),
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                ),

              ],
            ),
    );
  }
}
