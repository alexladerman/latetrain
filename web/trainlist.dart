import 'package:polymer/polymer.dart';
import 'package:google_maps/google_maps.dart';
import 'dart:html';
import 'dart:js';
import 'dart:math' as math;
//import 'dart:convert';
//import 'package:xml/xml.dart';

@CustomTag('train-list')
class TrainList extends PolymerElement {
  
  @observable String from = "lund";
  @observable String to = "ystad";
    
  @observable List start_points;
  @observable List end_points;
  List _start_points = new List();
  List _end_points = new List(); 
 
  final map_options = new MapOptions()
    ..zoom = 8
    ..center = new LatLng(55.789320158148726, 13.816097643683882)
    ..mapTypeId = MapTypeId.ROADMAP
    ;
  
  GMap map;
   
  TrainList.created() : super.created() {
    
    map = new GMap(querySelector("#map-canvas"), map_options);
    
    map.onZoomChanged.listen((ignored) => print('zoom: ${map.zoom}'));
    map.onCenterChanged.listen((ignored) => print('center: ${map.center}'));
    
    plotDepartureAndDestinationPoints(from, to);
    
  }

  plotDepartureAndDestinationPoints(String from, String to) {
    HttpRequest.request('http://www.labs.skanetrafiken.se/v2.2/querypage.asp?inpPointFr=$from&inpPointTo=$to')
    .then((HttpRequest request) {
      points(request, _start_points, 2);
      points(request, _end_points, 3);
    })
    .catchError((Error error) {
      window.console.error(error.toString());
    }).whenComplete(() {
        map.panTo(_end_points.last.position);
        start_points = _start_points;
        end_points = _end_points;
    });
  }
  
  void points(HttpRequest request, List output_list, int sequnce_node_index) {
    request.responseXml.nodes.first.firstChild.firstChild.firstChild.nodes.elementAt(sequnce_node_index).nodes.forEach((E) {
      int x = int.parse(E.nodes.firstWhere((p) => p.nodeName == "X", orElse: () => null).text);
      int y = int.parse(E.nodes.firstWhere((p) => p.nodeName == "Y", orElse: () => null).text);
      
      var rt90_point = context.callMethod('grid_to_geodetic', [x, y]);
      LatLng latlng_point = new LatLng(rt90_point[0], rt90_point[1]);
      output_list.add(
        new Marker(new MarkerOptions()
          ..position = latlng_point
          ..map = map
          ..title = E.nodes.firstWhere((p) => p.nodeName == "Name", orElse: () => null).text
          )
      );
    });
  }
     
}
