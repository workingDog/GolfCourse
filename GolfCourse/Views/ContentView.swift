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
    
    @Query private var golfCourses: [GolfCourse]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showCourse = true
    @State private var courses: [Int64] = [544123041, 487691175, 706245604, 138736088]
    @State private var courseid: Int64 = 544123041
    
    @State private var pinTapped: Int64?
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
            Map(position: $cameraPosition) {
                if selectedCourse != nil && showCourse {
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
                        if pinTapped != nil {
                            PathToPin(element: element)
                        }
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
            if let coords = selectedCourse?.elements.first?.coordinate {
                userLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            }
        }

        // testing
        .onAppear {
            print("\n---> stored golf courses with details in SwiftData")
            for gc in golfCourses {
                if gc.elements.count > 2 {
                    print("---> gc: \(gc.name)  gc: \(gc.osmID)")
                }
            }
            print()
        }

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
    
    private func courseName(of osmid: Int64) -> String {
        if let theCourse = golfCourses.first(where: { $0.osmID == osmid }),
        let name = theCourse.name {
            return name
        }
        return "no name"
    }

    @MapContentBuilder
    func PathToPin(element: OSMElementModel) -> some MapContent {
        if element.osmID == pinTapped {
            if let thePin = element.centerLocation {
                let distance = userLocation.distance(from: thePin)

                let labelCoordinate = Utility.pointAlongLine(
                    from: userLocation.coordinate,
                    to: thePin.coordinate,
                    fraction: 0.9
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
    }
    
    @MapContentBuilder
    func PointView(element: OSMElementModel) -> some MapContent {
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
                    Button {
                        pinTapped = pinTapped == element.osmID ? nil : element.osmID
                    } label: {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
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



/*
 golfCourses
 544123041
 500668040
 
 706245604
 487691175
 708715709
 138736091
 138736088
 138736091
 
 */


/*
 
 
//        .task {
//            do {
//                print("---> start import all courses")
//                try await OverpassClient().importGolfCourses(modelContext)
//                print("---> finished import all courses")
//            } catch {
//                print(error)
//            }
//        }

//        .task {
//            do {
//                try await OverpassClient().importOneGolfCourse(
//                    modelContext, golfCourses: golfCourses, wayid: courseid
//                )
//                print("---> done import \(courseid)")
//            } catch {
//                print(error)
//            }
//        }

 
 //        .onAppear {
 //            if let resutls = golfCourses.first(where: {$0.osmID == 697251926}) {
 //                print("---> resutls: \(resutls.elements.count)")
 //                for el in resutls.elements {
 //                    if el.geometry != nil {
 //                        print("---> type: \(el.type) members: \(el.members?.count)  geom: \(el.geometry?.count)")
 //                    }
 //                }
 //            }
 //        }
 
//        .task {
//            do {
//                try await OverpassClient().importOneGolfCourse(
//                    modelContext, golfCourses: golfCourses, wayid: courseid
//                )
//                print("---> done import task")
//        //        let resutls = try await OverpassClient().getGolfCourse(osmID: courseid)
//        //        print("---> fetching resutls: \(resutls.elements.count)")
//            } catch {
//                print(error)
//            }
//        }

*/
