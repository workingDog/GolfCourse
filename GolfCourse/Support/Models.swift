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
    @Attribute(.unique) var osmKey: String
    var osmID: Int64
    var name: String?
    var tags: [String: String]?
    
    @Relationship(deleteRule: .cascade, inverse: \OSMElementModel.golfCourse)
    var elements: [OSMElementModel] = []

    init(osmID: Int64, name: String?, tags: [String: String]?) {
        self.osmID = osmID
        osmKey = "way/\(osmID)"
        self.name = name
        self.tags = tags
    }
}

@Model
final class OSMElementModel {
    @Attribute(.unique) var osmKey: String
    var type: String
    var osmID: Int64 // <--- here 
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

    init(element: OSMElement) {
        osmKey = element.id
        type = element.type
        osmID = element.osmID
        tags = element.tags
        lat = element.lat
        lon = element.lon
        center = element.center
        geometry = element.geometry
        members = element.members
    }
}
