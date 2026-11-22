//
//  ClubsMapView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/22.
//

import SwiftUI
import SwiftData
import MapKit


struct ClubsMapView: View {
    @Binding var path: [GroupDestination]
    
    @Query private var clubs: [ClubModel]
    
    @State private var mapSelection: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            ForEach(clubs) { club in
                Marker(club.name ?? "Golf Club",
                       coordinate: CLLocationCoordinate2D(
                        latitude: club.lat,
                        longitude: club.lng
                       ))
                .tag(club.id)
            }
        }
        .onChange(of: mapSelection) {
            if let id = mapSelection {
                path.append(.club(id))
            }
        }
    }
    
}
