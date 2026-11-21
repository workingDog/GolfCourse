//
//  ContentView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftUI
import SwiftData
import MapKit


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var clubs: [ClubModel]
    
    @AppStorage("storedMapStyle") private var mapType = 0
    
    private var selectedClub: ClubModel? {
        clubs.first { $0.id == selectedClubID }
    }
    
    private var selectedPin: FeatureModel? {
        selectedClub?.features.first { $0.osm == selectedPinID }
    }
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedClubID: String? = "osm-jp-2555"
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
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection) {
                
                // All golf clubs
                ForEach(clubs) { club in
                    Marker(club.name ?? "Golf Club",
                           coordinate: CLLocationCoordinate2D(
                            latitude: club.lat,
                            longitude: club.lng
                           ))
                    .tag(club.id)
                }
                
                if let club = selectedClub {
                    
                    // Selected club boundary
                    ForEach(Array(club.boundary.enumerated()), id: \.offset) { item in
                        MapPolygon(coordinates: Utility.coordinates(item.element))
                            .foregroundStyle(.green.opacity(0.15))
                    }
                    
                    // Hole paths
                    ForEach(club.courses) { course in
                        ForEach(course.holes) { hole in
                            if hole.path.count > 1 {
                                MapPolyline(coordinates: Utility.coordinates(hole.path))
                                    .stroke(.blue, lineWidth: 3)
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
                                Annotation( "",
                                            coordinate: CLLocationCoordinate2D(
                                                latitude: point[0],
                                                longitude: point[1]
                                            ),
                                            anchor: .bottom
                                ) {
                                    Image(systemName: "flag.fill")
                                        .font(.title3)
                                        .foregroundStyle(.red)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if selectedPinID == feature.osm {
                                                selectedPinID = nil
                                            } else {
                                                selectedClubID = club.id
                                                selectedPinID = feature.osm
                                            }
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
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPins.toggle()
                    } label: {
                        Image(systemName: showPins ?  "flag.fill" : "flag")
                            .foregroundStyle(Color.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Club", selection: $selectedClubID) {
                            ForEach(clubs) { club in
                                Text(club.name ?? "Unknown Club").tag(club.id)
                            }
                        }
                    } label: {
                        Image(systemName: "figure.golf")
                    }
                }
            }
        }
        .onChange(of: mapSelection) { oldValue, newValue in
            if let newValue {
                selectedClubID = newValue
            }
        }
        .onChange(of: selectedClubID) {
            // for testing
            if let club = selectedClub {
                let coord = CLLocationCoordinate2D(latitude: club.lat, longitude: club.lng)
                let offset = 150.0 / 111_000.0
                userLocation = CLLocation(latitude: coord.latitude + offset, longitude: coord.longitude)
            }
            zoomToClub()
        }
        .task {
            print("---> clubs in SwiftData: \(clubs.count)\n")
            zoomToClub()
            
            // ---> selectedClub: Optional("若洲ゴルフリンクス")  Optional("osm-jp-2555")
            //      print("---> selectedClub: \(selectedClub?.name)  \(selectedClub?.id)")
            
            //            let featureTypes = Set(clubs.flatMap { $0.features.map(\.type) })
            //            print("Feature types: \(featureTypes.sorted())")
            
            // load all the data into SwiftData once
            guard clubs.isEmpty else { return }
            print("---> loading clubs from japan.json")
            let clubsLoaded = Utility.loadClubs()
            let usefulClubs = clubsLoaded.filter(\.hasMeaningfulData)
            do {
                for club in usefulClubs {
                    modelContext.insert(ClubModel(club: club))
                }
                try modelContext.save()
                print("---> Imported \(usefulClubs.count) clubs")
            } catch {
                print("SwiftData import error: \(error)")
            }
        }
        
    }
    
    func zoomToClub() {
        guard let club = selectedClub else { return }
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
