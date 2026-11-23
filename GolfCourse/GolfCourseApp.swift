//
//  GolfCourseApp.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftUI
import SwiftData


/*
To add a number of golfers as a group, and display their locations on the map.
 
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


@main
struct GolfCourseApp: App {

    var sharedModelContainer: ModelContainer = {
        let appSupportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        do {
            try FileManager.default.createDirectory(
                at: appSupportDir,
                withIntermediateDirectories: true
            )
        } catch {
            print("Failed to create Application Support directory:", error)
        }

        let storeURL = appSupportDir.appending(path: "golfjapan.sqlite")

        print("---> database at: \(storeURL.absoluteString)\n")

        let schema = Schema([ClubModel.self, CourseModel.self,  HoleModel.self, FeatureModel.self])
        
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Could not create ModelContainer: ", error)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            GroupView()
        }
        .modelContainer(sharedModelContainer)
    }
}
