//
//  Models.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//
import Foundation
import CoreLocation
import SwiftData


struct OverpassClient {

    private let endpoint = URL(string: "https://overpass-api.de/api/interpreter")!
    private let decoder = JSONDecoder()
    
    func fetch(_ query: String) async throws -> OverpassResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 150
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("JapanGolfMap/1.0 (contact: warton@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        var components = URLComponents()
        components.queryItems = [ URLQueryItem(name: "data", value: query) ]
        
        guard let encodedQuery = components.percentEncodedQuery,
              let body = encodedQuery.data(using: .utf8) else {
            throw URLError(.unknown)
        }
        request.httpBody = body

        print("\n---> fetching")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("---> done \n")
        
  //      print("---> data: \n\(String(data: data, encoding: .utf8) as AnyObject)\n")
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("Overpass HTTP \(http.statusCode): \(message)")
            throw URLError(.badServerResponse)
        }
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(OverpassResponse.self, from: data)
    }
    
    func golfCoursesQuery() -> String {
        """
        [out:json][timeout:180];
        area["ISO3166-1"="JP"][admin_level=2]->.japan;
        (
            way["leisure"="golf_course"](area.japan);
            relation["leisure"="golf_course"](area.japan);
        );
        out geom;
        """
    }
    
    func golfCourseDetailsQuery2(osmID: Int64, type: String = "way") -> String {
        """
        [out:json][timeout:180];

        \(type)(\(osmID))->.boundary;
        .boundary map_to_area->.course;

        (
            .boundary;
            nwr["golf"](area.course);
            relation["type"="sport"]["golf"="course"](area.course);
        )->.features;

        (
            .features;
            rel(bw.features);
        )->.related;

        .related out body geom;
        .related >>;
        out body geom;
        """
    }
    
    func golfCourseDetailsQuery(osmID: Int64, type: String = "way") -> String {
        """
        [out:json][timeout:180];

        // 1. Retrieve the golf course boundary
        way(544123041)->.course;

        // 2. Convert the boundary into an area
        .course map_to_area -> .courseArea;

        // 3. Retrieve all golf-related features inside the course
        (
            .course;
            nwr(area.courseArea)["golf"];
            nwr(area.courseArea)["sport"="golf"];
        )->.courseElements;

        // 4. Retrieve the underlying elements of relations
        .courseElements >> -> .courseMembers;

        // 5. Combine everything
        (
            .courseElements;
            .courseMembers;
        );

        // 6. Return complete geometry
        out geom;
        """
    }
    
    func importGolfCourses(_ modelContext: ModelContext) async throws {
        do {
            let resp1 = try await getGolfCourses()
            for boundary in resp1.elements {
                let course = GolfCourse(
                    osmID: boundary.osmID,
                    name: boundary.tags?["name"],
                    tags: boundary.tags
                )
                modelContext.insert(course)
            }
            try modelContext.save()
            print("Golf courses imported: \(resp1.elements.count)")
        } catch {
            print("Golf course import error: \(error)")
        }
    }
    
    func importGolfCoursesDetails(_ modelContext: ModelContext, golfCourses: [GolfCourse]) async throws {
        do {
            for gc in golfCourses.prefix(3) {
                let response = try await getGolfCourse(osmID: gc.osmID)
                print("---> gc.osmID: \(gc.osmID)")
                
                for element in response.elements {
                    let key = element.id
                    let descriptor = FetchDescriptor<OSMElementModel>(
                        predicate: #Predicate { $0.osmKey == key }
                    )
                    let osmElement: OSMElementModel
                    if let existing = try modelContext.fetch(descriptor).first {
                        osmElement = existing
                    } else {
                        osmElement = OSMElementModel(element: element)
                        modelContext.insert(osmElement)
                    }
                    if !gc.elements.contains(where: { $0.osmKey == key }) {
                        gc.elements.append(osmElement)
                        print("---> gc adding: \(gc.osmID)")
                    }
                }
                
                try modelContext.save()
                print("Golf courses elements imported: \(response.elements.count)")
            }
        } catch {
            print("Golf course details import error: \(error)")
        }
    }
    
    func importOneGolfCourse(_ modelContext: ModelContext, golfCourses: [GolfCourse], wayid: Int64) async throws {
        do {
            if let gc = golfCourses.first(where: {$0.osmID == wayid}) {
                
                let response = try await getGolfCourse(osmID: gc.osmID)
                print("---> gc.osmID: \(gc.osmID)")
                
                for element in response.elements {
                    let key = element.id
                    let descriptor = FetchDescriptor<OSMElementModel>(
                        predicate: #Predicate { $0.osmKey == key }
                    )
                    let osmElement: OSMElementModel
                    if let existing = try modelContext.fetch(descriptor).first {
                        osmElement = existing
                    } else {
                        osmElement = OSMElementModel(element: element)
                        modelContext.insert(osmElement)
                    }
                    if !gc.elements.contains(where: { $0.osmKey == key }) {
                        gc.elements.append(osmElement)
                        print("---> gc adding: \(gc.osmID)")
                    }
                }
                
                try modelContext.save()
                print("Golf courses elements imported: \(response.elements.count)")
            }
            
        } catch {
            print("Golf course details import error: \(error)")
        }
    }
    
    func getGolfCourses() async throws -> OverpassResponse {
        try await fetch(golfCoursesQuery())
    }

    func getGolfCourse(osmID: Int64, type: String = "way") async throws -> OverpassResponse {
        try await fetch(golfCourseDetailsQuery(osmID: osmID, type: type))
    }

}
