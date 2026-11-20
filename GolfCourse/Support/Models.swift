//
//  Models.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftData
import CoreLocation


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

    init(element: OSMElement) {
        type = element.type
        osmID = element.osmID
        tags = element.tags
        lat = element.lat
        lon = element.lon
        center = element.center
        geometry = element.geometry
        members = element.members
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

    var coordinate: CLLocationCoordinate2D? {
        if let lat, let lon {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return center?.mapCoordinate
    }

    enum CodingKeys: String, CodingKey {
        case type, tags, lat, lon, center, geometry, members
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
