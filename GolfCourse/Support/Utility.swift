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
    
}
