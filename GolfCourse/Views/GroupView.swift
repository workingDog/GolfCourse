//
//  GroupView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/21.
//

import SwiftUI

/*
 1 Create Firebase project and register the iOS application
 2 Install Firebase SDK using Swift Package Manager
 3 Initialise Firebase in SwiftUI
 4 Implement anonymous authentication
 5 Create and join golfing groups
 6 Implement Realtime Database JSON storage
 7 Implement GPS location sharing
 8 Display other golfers on your existing map
 9 Implement disconnect handling and group cleanup
 10 Configure Firebase Security Rules
 11 Implement App Check with Apple App Attest
 */


/*
 Bundle id: com.ringow.GolfCourse
 
 //= "osm-jp-2555"
 */

import SwiftUI
import SwiftData


enum GroupDestination: Hashable {
    case club(String)
    case map
}

struct GroupView: View {
    @State private var path: [GroupDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ClubSelectionView()
        }
    }
    
}
