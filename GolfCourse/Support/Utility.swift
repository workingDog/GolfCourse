//
//  Utility.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/19.
//
import Foundation
import CoreLocation
import SwiftUI
import MapKit


extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func trimLowercased() -> String {
        trim().lowercased()
    }
}

struct Utility {

    static func asString(_ dist: Double) -> String {
        if dist < 1_000 {
            return "\(Int(dist)) m "
        } else {
            return String(format: "%.1f km ", dist / 1_000)
        }
    }
    
    static func mapMidpoint(_ start: CLLocationCoordinate2D, _ end: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let a = MKMapPoint(start)
        let b = MKMapPoint(end)
        return MKMapPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2).coordinate
    }

    static func pointAlongLine(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        
        let a = MKMapPoint(start)
        let b = MKMapPoint(end)

        let point = MKMapPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
        return point.coordinate
    }
    
    static func coordinates(_ path: HolePath) -> [CLLocationCoordinate2D] {
        path.compactMap { point in
            guard point.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
    }
    
    static func featureColor(_ type: String) -> Color {
        switch type {
            case "green": .green
            case "fairway": .mint
            case "bunker": .yellow
            case "water_hazard": .blue
            case "tee": .orange
            default: .gray
        }
    }
    
    static func loadClubs() -> [Club] {
        guard
            let url = Bundle.main.url(forResource: "japan", withExtension: "json"),
            let data = try? Data(contentsOf: url)
                else {
            return []
        }
        do {
            let result = try JSONDecoder().decode(CountryData.self, from: data)
            return result.clubs
        } catch {
            print("Failed to load data:", error)
            return []
        }
    }

}
