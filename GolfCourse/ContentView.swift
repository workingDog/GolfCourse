//
//  ContentView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftUI
import SwiftData
import MapKit


/*
 golfCourses
 544123041
 
 697251926
 550991228
 379137416
 */

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var golfCourses: [GolfCourse]
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    let courseid: Int64 = 544123041
    
    private var selectedCourse: GolfCourse? {
        golfCourses.first { $0.osmID == courseid }
    }
    
    private var displayedElements: [OSMElementModel] {
        guard let course = selectedCourse else { return [] }
        var seenHoleRefs = Set<String>()
        return course.elements.filter { element in
            guard element.tags?["golf"] == "hole", let ref = element.tags?["ref"] else {
                return true
            }
            return seenHoleRefs.insert(ref).inserted
        }
    }
    
    var body: some View {
        Map(position: $cameraPosition) {
            if selectedCourse != nil {
                
                ForEach(displayedElements) { element in
                    
                    let golfType = element.tags?["golf"] ?? ""
                    let name = element.tags?["name"] ?? ""
                    
                    // MARK: - Geometry
                    
                    if let geometry = element.geometry, !geometry.isEmpty {
                        CourseFeaturesView(geometry: geometry, element: element)
                    }
                    
                    // MARK: - Point elements
                    
                    else if let coordinate = element.coordinate {
                        Annotation(name.isEmpty ? golfType : name, coordinate: coordinate) {
                            if golfType == "clubhouse" {
                                Image(systemName: "building.2")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                            } else if golfType == "pin" {
                                Image(systemName: "flag.fill")
                                    .foregroundStyle(.red)
                                    .font(.title3)
                            }
                        }
                    }
                    
                    // MARK: - Relation members
                    
                    if let members = element.members {
                        ForEach(members) { member in
                            if let geometry = member.geometry, !geometry.isEmpty {
                                let coordinates = geometry.map(\.mapCoordinate)
                                if coordinates.count >= 3 {
                                    MapPolygon(coordinates: coordinates)
                                        .foregroundStyle(
                                            member.role == "inner"
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
                    
                }
            }
        }
        
    }
    
    @MapContentBuilder
    func CourseFeaturesView(geometry: [OSMCoordinate], element: OSMElementModel) -> some MapContent {
        
        let golfType = element.tags?["golf"] ?? ""
        let ref = element.tags?["ref"] ?? ""
        
        let coordinates = geometry.map(\.mapCoordinate)
        
        switch golfType {
            
        case "course":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.blue.opacity(0.15))
                    .stroke(.blue, lineWidth: 2)
            }
            
        case "fairway":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.green.opacity(0.35))
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
                    .foregroundStyle(.yellow.opacity(0.7))
            }
            
        case "water_hazard":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.cyan.opacity(0.5))
            }
            
        case "rough":
            if coordinates.count >= 3 {
                MapPolygon(coordinates: coordinates)
                    .foregroundStyle(.green.opacity(0.15))
            }
            
        case "cartpath":
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.gray, lineWidth: 2)
            }
            
        case "hole":
            if let coordinate = element.center?.mapCoordinate
                ?? element.geometry?.first?.mapCoordinate {
                Annotation("Hole \(ref)", coordinate: coordinate) {
                    Text(ref.isEmpty ? "?" : ref)
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
                MapPolygon(coordinates: coordinates).foregroundStyle(.purple.opacity(0.2))
            } else if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates).stroke(.purple, lineWidth: 2)
            }
        }
    }
    
}


/*

//        .onAppear {
//            if let course = golfCourses.first(where: { $0.osmID == courseid }) {
//                for element in course.elements where element.tags?["golf"] == "hole" {
//                    print(element.osmID, element.tags ?? [:], element.type)
//                }
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

 
 .onAppear {
     if let resutls = golfCourses.first(where: {$0.osmID == courseid}) {
         print("---> resutls: \(resutls.elements.count)")
         for el in resutls.elements {
            // print("---> el.members: \(el.members?.count)")
             if let members = el.members {
                 for member in members {
                     if member.geometry != nil {
                         print("---> geom: \(member.geometry?.count)")
                     }
                 }
             }
         }
     }
 }
 
 
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
 //                let resutls = try await OverpassClient().getGolfCourse(osmID: 697251926)
 //                print("---> resutls: \(resutls.elements.count)")
 //            } catch {
 //                print(error)
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
