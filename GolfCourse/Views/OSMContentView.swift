//
//  OSMContentView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/20.
//
//
//  ContentView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//
/*
import SwiftUI
import SwiftData
import MapKit


struct OSMContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var golfCourses: [GolfCourse]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showCourse = true
    @State private var courses: [Int64] = [544123041, 138736088]
    // [544123041, 487691175, 138736088]
    @State private var courseid: Int64 = 544123041
    
    @State private var pinTapped: Int64?
    @State private var pinsLocations: [Int64 : CLLocation] = [:]
    @State private var userLocation = CLLocation()  // for testing
    
    @AppStorage("storedMapStyle") private var mapType = 0
    
    var mapStyle: MapStyle {
        switch(mapType) {
            case 0: .standard()
            case 1: .hybrid()
            case 2: .imagery(elevation: .realistic)
            default: .standard(elevation: .automatic, pointsOfInterest: .excludingAll)
        }
    }
    
    private var selectedCourse: GolfCourse? {
        golfCourses.first(where: { $0.osmID == courseid })
    }
    
    // removes duplicate ref elements (the hole number)
    private var displayedElements: [OSMElementModel] {
        guard let course = selectedCourse else { return [] }
        var seenHoleRefs = Set<String>()
        return course.elements.filter { element in
            guard element.golfType == "hole", !element.ref.isEmpty else {
                return true
            }
            return seenHoleRefs.insert(element.ref).inserted
        }
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $pinTapped) {
                if selectedCourse != nil && showCourse {
                    CourseView()
                    if pinTapped != nil && pinsLocations[pinTapped!] != nil {
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
                        showCourse.toggle()
                    } label: {
                        Image(systemName: "figure.golf")
                            .foregroundStyle(Color.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(courses, id: \.self) { course in
                            Button {
                                courseid = course
                            } label: {
                                HStack {
                                    Text(courseName(of: course))
                                        .foregroundStyle(courseid == course ? Color.green : Color.primary)
                                    Spacer()
                                    if courseid == course {
                                        Image(systemName: courseid == course ? "checkmark" : "circle")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "list.triangle")
                    }
                }
            }
        }
        .task(id: selectedCourse) {
            makePinsLocations()
            
            // for testing
            if let coords = selectedCourse?.elements.first?.coordinate {
                userLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            }
        }
        
        // testing
//        .onAppear {
//            print("\n========== GOLF COURSE DETAILS ==========")
//            for gc in golfCourses {
//                let pins = gc.elements.filter { $0.golfType == "pin" }
//                let holes = gc.elements.filter { $0.golfType == "hole" }
//
//                guard !pins.isEmpty || !holes.isEmpty else { continue }
//
//                print("\nCOURSE: \(gc.name ?? "Unnamed") (ID: \(gc.osmID))")
//
//                print("\n--- PIN NODES (\(pins.count)) ---")
//                for pin in pins {
//                    print("""
//                        Pin ID: \(pin.osmID)
//                        Coordinates: \(String(describing: pin.geometry))
//                        Tags: \(String(describing: pin.tags))
//                        """)
//                }
//
//                print("\n--- HOLE WAYS (\(holes.count)) ---")
//                for hole in holes {
//                    print("""
//                        Hole ID: \(hole.osmID)
//                        Ref: \(hole.ref)
//                        Nodes: \(String(describing: hole.nodes))
//                        Geometry: \(String(describing: hole.geometry))
//                        """)
//                }
//            }
//            print("\n========== END ==========\n")
//        }
        
//        .onAppear {
//            for gc in golfCourses {
//                let pins = gc.elements.filter { $0.golfType == "pin" }
//                let holes = gc.elements.filter { $0.golfType == "hole" }
//                guard !pins.isEmpty else { continue }
//                print("\nCOURSE: \(gc.name ?? "Unnamed")")
//                print("Pins: \(pins.count), Holes: \(holes.count)")
////                for pin in pins.prefix(3) {
////                    print("Pin: \(pin.osmID), golfCourse nil: \(pin.golfCourse == nil)")
////                }
//                for pin in pins {
//                    print("Pin: \(pin.osmID)")
//                    print("Associated hole: \(pin.associatedHoleNumber ?? "nil")")
//                }
//            }
//        }
        
//        .onAppear {
//            print("\n---> stored golf courses with details in SwiftData")
//            for gc in golfCourses {
//                if gc.elements.count > 2 {
//                    print("---> gc: \(gc.name)  gc: \(gc.osmID)")
//                }
//            }
//            print()
//        }
        
//        .task {
//            for course in courses {
//                do {
//                    print("---> start import details of \(course)")
//                    try await OverpassClient().importOneGolfCourse(
//                        modelContext, golfCourses: golfCourses, osmID: course
//                    )
//                    print("---> done import details of \(course)\n")
//                } catch {
//                    print(error)
//                }
//            }
//        }
        
//        .task {
//            do {
//                print("---> start import all courses, but not their details")
//                try await OverpassClient().importGolfCourses(modelContext)
//                print("---> finished import all courses")
//            } catch {
//                print(error)
//            }
//        }
        
    }
    
    private func makePinsLocations() {
        pinsLocations = [:]
        // create the pins dictionary
        if let pins = selectedCourse?.elements.filter({$0.golfType == "pin"}) {
            for pin in pins {
                if let pinLoc = pin.centerLocation {
                    pinsLocations[pin.osmID] = pinLoc
                }
            }
        }
    }
    
    private func courseName(of osmid: Int64) -> String {
        if let theCourse = golfCourses.first(where: { $0.osmID == osmid }),
           let name = theCourse.name {
            return name
        }
        return "no name"
    }
    
    @MapContentBuilder
    func CourseView() -> some MapContent {
        ForEach(displayedElements) { element in
            if let geometry = element.geometry, !geometry.isEmpty {
                CourseFeaturesView(geometry: geometry, element: element)
            }
            else  {
                PointView(element: element)
            }
            if let members = element.members {
                MembersView(members: members)
            }
        }
    }
    
    @MapContentBuilder
    func PathToPin() -> some MapContent {
        if let thisPinid = pinTapped, let thePin = pinsLocations[thisPinid] {
            
            let distance = userLocation.distance(from: thePin)
            
            let labelCoordinate = Utility.pointAlongLine(
                from: thePin.coordinate,
                to: userLocation.coordinate,
                fraction: 0.95
            )
            
            MapPolyline(coordinates: [userLocation.coordinate, thePin.coordinate])
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1, 10]))
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

    
    @MapContentBuilder
    func PointView(element: OSMElementModel) -> some MapContent {
        if let coordinate = element.coordinate {
            if element.golfType == "pin" {
                Marker(
                    element.associatedHoleNumber ?? "",
                    systemImage: "flag.fill",
                    coordinate: coordinate
                )
                .tint(.red)
                .tag(element.osmID)
            }
        }
    }

    @MapContentBuilder
    func PointView1(element: OSMElementModel) -> some MapContent {
        if let coordinate = element.coordinate {
            Annotation(
                element.name.isEmpty ? element.golfType : element.name,
                coordinate: coordinate
            ) {
                if element.golfType == "clubhouse" {
                    Image(systemName: "building.2")
                        .foregroundStyle(.red)
                        .font(.title3)
                } else if element.golfType == "pin" {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                        .onTapGesture {
                            pinTapped = pinTapped == element.osmID ? nil : element.osmID
                        }
                }
            }
        }
    }
    
    @MapContentBuilder
    func MembersView(members: [OSMMember]) -> some MapContent {
        ForEach(members) { member in
            if let geometry = member.geometry, !geometry.isEmpty {
                let coordinates = geometry.map(\.mapCoordinate)
                if coordinates.count >= 3 {
                    MapPolygon(coordinates: coordinates)
                        .foregroundStyle(member.role == "inner"
                                         ? .white.opacity(0.5)
                                         : .orange.opacity(0.2)
                        )
                } else if coordinates.count >= 2 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(.orange, lineWidth: 2)
                }
            }
        }
    }
    
    @MapContentBuilder
    func CourseFeaturesView(geometry: [OSMCoordinate], element: OSMElementModel) -> some MapContent {
        let coordinates = geometry.map(\.mapCoordinate)
        
        switch element.golfType {
            
        case "course":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.blue.opacity(0.2))
                    .stroke(.blue, lineWidth: 2)
            }
            
        case "fairway":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.green.opacity(0.4))
            }
            
        case "green":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.green)
            }
            
        case "tee":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.blue.opacity(0.5))
            }
            
        case "bunker":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.yellow)
            }
            
        case "water_hazard":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.cyan.opacity(0.5))
            }
            
        case "rough":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.green.opacity(0.3))
            }
            
        case "cartpath":
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.gray, lineWidth: 4)
            }
            
        case "hole":
            if let coordinate = element.center?.mapCoordinate
                ?? element.geometry?.first?.mapCoordinate {
                Annotation("Hole \(element.ref)", coordinate: coordinate) {
                    Text(element.ref.isEmpty ? "?" : element.ref)
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(7)
                        .background(.white, in: Circle())
                        .overlay {
                            Circle().stroke(.green, lineWidth: 2)
                        }
                }
            }
            
        default:
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.clear)
                    .stroke(.green, lineWidth: 2)
            } else if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .foregroundStyle(.purple.opacity(0.2))
                    .stroke(.purple, lineWidth: 2)
            }
        }
    }
    
}

*/
