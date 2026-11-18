//
//  GolfCourseApp.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/17.
//

import SwiftUI
import SwiftData

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

        let storeURL = appSupportDir.appending(path: "golf.sqlite")

        print("---> database at: \(storeURL.absoluteString)\n")

        let schema = Schema([GolfCourse.self, OSMElementModel.self])
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

