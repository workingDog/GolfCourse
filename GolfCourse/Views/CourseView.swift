//
//  ContentView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftUI
import SwiftData
import MapKit


struct CourseView: View {
    @Environment(\.modelContext) private var modelContext
    
    let club: ClubModel
    
    @AppStorage("storedMapStyle") private var mapType = 0
    
    private var selectedPin: FeatureModel? {
        club.features.first { $0.osm == selectedPinID }
    }
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPinID: String?
    @State private var mapSelection: String?
    @State private var showPins = true
    
    // for testing
    @State private var userLocation = CLLocation(latitude: 35.622, longitude: 139.837)
    
    var mapStyle: MapStyle {
        switch(mapType) {
        case 0: .standard()
        case 1: .hybrid()
        case 2: .imagery(elevation: .realistic)
        default: .standard(elevation: .automatic, pointsOfInterest: .excludingAll)
        }
    }
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            
            // User location
            Annotation("", coordinate: userLocation.coordinate) {
                PulsatingLocation()
            }
            
            // Selected club boundary
            ForEach(Array(club.boundary.enumerated()), id: \.offset) { item in
                MapPolygon(coordinates: Utility.coordinates(item.element))
                    .foregroundStyle(.green.opacity(0.15))
            }

            // Hole paths
            ForEach(club.courses) { course in
                ForEach(course.holes, id: \.number) { hole in
                    let coordinates = Utility.coordinates(hole.path)
                    if coordinates.count > 1 {
                        MapPolyline(coordinates: coordinates).stroke(.blue, lineWidth: 3)

                        Annotation("", coordinate: coordinates[coordinates.count / 2]) {
                            Text("\(hole.number)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(.blue, in: Circle())
                                .overlay {
                                    Circle().stroke(.white, lineWidth: 2)
                                }
                        }
                    }
                }
            }
            
            // Golf course features
            ForEach(club.features) { feature in
                // Feature polygons
                ForEach(Array(feature.outer.enumerated()), id: \.offset) { item in
                    MapPolygon(coordinates: Utility.coordinates(item.element))
                        .foregroundStyle(Utility.featureColor(feature.type).opacity(0.4))
                }
                
                if showPins {
                    // Feature points (including pins)
                    if let point = feature.point, point.count >= 2 {
                        Annotation( "", coordinate: CLLocationCoordinate2D(
                            latitude: point[0],
                            longitude: point[1]
                        ), anchor: .bottom
                        ) {
                            Image(systemName: "flag.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPinID = selectedPinID == feature.osm
                                    ? nil : feature.osm
                                }
                        }
                    }
                }
            }
            
            // Path and distance to the selected pin
            if selectedPinID != nil, showPins {
                PathToPin()
            }
            
        }
        .mapStyle(mapStyle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $mapType) {
                    Text("Standard").tag(0)
                    Text("Hybrid").tag(1)
                    Text("Satellite").tag(2)
                }
                .pickerStyle(.segmented)
   //             .frame(width: 240)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPins.toggle()
                } label: {
                    Image(systemName: showPins ?  "flag.fill" : "flag")
                        .foregroundStyle(Color.red)
                }
            }
        }
        .task {
            zoomToClub()
            // for testing
            let coord = CLLocationCoordinate2D(latitude: club.lat, longitude: club.lng)
            let offset = 150.0 / 111_000.0
            userLocation = CLLocation(latitude: coord.latitude + offset, longitude: coord.longitude)
        }
    }
    
    func zoomToClub() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: club.lat, longitude: club.lng),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }
    
    @MapContentBuilder
    func PathToPin() -> some MapContent {
        if let point = selectedPin?.point, point.count >= 2 {
            let thePin = CLLocation(latitude: point[0], longitude: point[1])
            let distance = userLocation.distance(from: thePin)
            
            // max 2km
            if distance <= 2000.0 {
                let labelCoordinate = Utility.pointAlongLine(
                    from: userLocation.coordinate,
                    to: thePin.coordinate,
                    fraction: 0.2
                )
                
                MapPolyline(coordinates: [userLocation.coordinate, thePin.coordinate])
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 10]))
                    .mapOverlayLevel(level: .aboveLabels)
                
                Annotation("", coordinate: labelCoordinate, anchor: .top) {
                    Text(Utility.asString(distance))
                        .font(.title3)
                        .padding(5)
                        .foregroundStyle(.white)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
}
