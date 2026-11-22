//
//  Models.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftData
import CoreLocation


//-------------------------------------------------------------------
//------------------------json---------------------------------------
//-------------------------------------------------------------------

struct CountryData: Codable {
    let format: Int
    let country: String
    let name: String
    let made: String
    let attribution: String
    let clubs: [Club]
}

struct Club: Codable {
    let id: String
    let osm: String
    let name: String?
    let lat: Double
    let lng: Double
    let bbox: [Double]
    let boundary: Rings
    let courses: [Course]
    let features: [CourseFeature]
    
    // club with pin data
    var hasMeaningfulData: Bool {
        features.contains { $0.geometry.point?.count == 2 }
    }
}

struct Course: Codable {
    let name: String?
    let complete: Bool
    let holeCount: Int
    let holes: [Hole]
    let notes: [String]
    let key: String
}

struct Hole: Codable {
    let n: Int
    let path: HolePath
}

struct CourseFeature: Codable {
    let osm: String
    let type: String
    let geometry: CourseGeometry
}

struct CourseGeometry: Codable {
    let point: Point?
    let outer: Rings
    let inner: Rings
}

typealias Point = [Double]
typealias HolePath = [Point]
typealias Rings = [HolePath]


//@Model
//final class DatasetModel {
//    @Attribute(.unique) var country: String
//
//    var format: Int
//    var name: String
//    var made: String
//    var attribution: String
//
//    @Relationship(deleteRule: .cascade, inverse: \ClubModel.dataset)
//    var clubs: [ClubModel] = []
//
//    init(data: CountryData) {
//        country = data.country
//        format = data.format
//        name = data.name
//        made = data.made
//        attribution = data.attribution
//    }
//}

@Model
final class ClubModel {
    @Attribute(.unique) var id: String
    
    var osm: String
    var name: String?
    var lat: Double
    var lng: Double
    var bbox: [Double]
    var boundary: Rings
    
    @Relationship(deleteRule: .cascade, inverse: \CourseModel.club)
    var courses: [CourseModel] = []
    
    @Relationship(deleteRule: .cascade, inverse: \FeatureModel.club)
    var features: [FeatureModel] = []
    
    init(club: Club) {
        id = club.id
        osm = club.osm
        name = club.name
        lat = club.lat
        lng = club.lng
        bbox = club.bbox
        boundary = club.boundary
        courses = club.courses.map { CourseModel(course: $0) }
        features = club.features.map { FeatureModel(feature: $0) }
        courses.forEach { $0.club = self }
        features.forEach { $0.club = self }
    }
}

@Model
final class CourseModel {
    var name: String?
    var complete: Bool
    var holeCount: Int
    var notes: [String]
    var key: String
    var club: ClubModel?
    
    @Relationship(deleteRule: .cascade, inverse: \HoleModel.course)
    var holes: [HoleModel] = []
    
    init(course: Course) {
        name = course.name
        complete = course.complete
        holeCount = course.holeCount
        notes = course.notes
        key = course.key
        holes = course.holes.map { HoleModel(hole: $0) }
        holes.forEach { $0.course = self }
    }
}

@Model
final class HoleModel {
    var number: Int
    var path: HolePath
    var course: CourseModel?
    
    init(hole: Hole) {
        number = hole.n
        path = hole.path
    }
}

@Model
final class FeatureModel {
    var osm: String
    var type: String
    var point: Point?  // [latitude, longitude]
    var outer: Rings
    var inner: Rings
    var club: ClubModel?
    
    init(feature: CourseFeature) {
        osm = feature.osm
        type = feature.type
        point = feature.geometry.point
        outer = feature.geometry.outer
        inner = feature.geometry.inner
    }
  
}


//-------------------------------------------------------------------
//------------------------Overpass-----------------------------------
//-------------------------------------------------------------------

@Model
final class GolfCourse {
    @Attribute(.unique) var osmID: Int64
    
    var name: String?
    var tags: [String: String]?
    
    @Relationship(deleteRule: .cascade, inverse: \OSMElementModel.golfCourse)
    var elements: [OSMElementModel] = []

    init(osmID: Int64, name: String?, tags: [String: String]?) {
        self.osmID = osmID
        self.name = name
        self.tags = tags
    }
}

@Model
final class OSMElementModel {
    @Attribute(.unique) var osmID: Int64
    
    var type: String
    var tags: [String: String]?
    var lat: Double?
    var lon: Double?
    var center: OSMCoordinate?
    var geometry: [OSMCoordinate]?
    var members: [OSMMember]?
    var nodes: [Int64]?
    
    var golfCourse: GolfCourse?

    var coordinate: CLLocationCoordinate2D? {
        if let lat, let lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return center?.mapCoordinate
    }
    
    var centerLocation: CLLocation? {
        if let lat, let lon {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }
    
    var associatedHoleNumber: String? {
        guard golfType == "pin", let golfCourse else { return nil }
        let refs = Set(golfCourse.elements.compactMap { element -> String? in
            guard element.golfType == "hole",
                  element.nodes?.contains(osmID) == true,
                  !element.ref.isEmpty else { return nil }
            return element.ref
        })
        return refs.count == 1 ? refs.first : nil
    }

    init(element: OSMElement) {
        type = element.type
        osmID = element.osmID
        tags = element.tags
        lat = element.lat
        lon = element.lon
        center = element.center
        geometry = element.geometry
        members = element.members
        nodes = element.nodes
    }

    var golfType: String { tags?["golf"] ?? "" }
    var name: String { tags?["name"] ?? "" }
    var ref: String { tags?["ref"] ?? "" }
    var hole: String { tags?["hole"] ?? "" }
}

struct Osm3S: Codable {
    let timestampOsmBase: Date
    let timestampAreasBase: Date
    let copyright: String

    enum CodingKeys: String, CodingKey {
        case timestampOsmBase = "timestamp_osm_base"
        case timestampAreasBase = "timestamp_areas_base"
        case copyright = "copyright"
    }
}

struct OverpassResponse: Codable {
    let version: Double
    let generator: String
    let osm3S: Osm3S
    let elements: [OSMElement]

    enum CodingKeys: String, CodingKey {
        case version = "version"
        case generator = "generator"
        case osm3S = "osm3s"
        case elements = "elements"
    }
}

struct OSMCoordinate: Codable, Identifiable {
    var id: String { "\(lat)/\(lon)" }

    let lat: Double
    let lon: Double

    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case lat, lon
    }
}

struct OSMElement: Codable, Identifiable {
    var id: String { "\(type)/\(osmID)" }
    
    let type: String
    let osmID: Int64
    let tags: [String: String]?
    let lat: Double?
    let lon: Double?
    let center: OSMCoordinate?
    let geometry: [OSMCoordinate]?
    let members: [OSMMember]?
    let nodes: [Int64]?

    var coordinate: CLLocationCoordinate2D? {
        if let lat, let lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return center?.mapCoordinate
    }

    enum CodingKeys: String, CodingKey {
        case type, tags, lat, lon, center, geometry, members, nodes
        case osmID = "id"
    }
}

struct OSMMember: Identifiable, Codable {
    var id: Int64 { ref }
    
    let type: String
    let ref: Int64
    let role: String?
    let geometry: [OSMCoordinate]?
}
