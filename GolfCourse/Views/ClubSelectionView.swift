//
//  ClubSelectionView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/22.
//
import SwiftUI
import SwiftUI
import SwiftData


struct ClubSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var clubs: [ClubModel]
    
    @State private var path: [GroupDestination] = []
    @State private var selectedClubID: String?
    @State private var searchText = ""    // "若洲ゴルフリンクス"  "osm-jp-2555"
    @State private var address = ""
    @State private var showMap = false
    
    private var filteredClubs: [ClubModel] {
        guard !searchText.trim().isEmpty else { return clubs }
        return clubs.filter {
            $0.name?.trim().localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .topLeading) {
                AppBackground().ignoresSafeArea()
                
                List(filteredClubs) { club in
                    Button {
                        selectedClubID = club.id
                    } label: {
                        Text(club.name ?? "Unknown Club")
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 3, trailing: 10))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search clubs")
                .navigationDestination(for: GroupDestination.self) { destination in
                    switch destination {
                    case .map:
                        ClubsMapView(path: $path)
                            .onDisappear {
                                showMap = false
                                searchText = ""
                            }
                    case .club(let id):
                        if let club = clubs.first(where: { $0.id == id }) {
                            CourseView(club: club)
                                .onDisappear {
                                    selectedClubID = nil
                                    searchText = ""
                                }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showMap.toggle()
                            if showMap {
                                path.append(.map)
                            }
                        } label: {
                            Image(systemName: "map")
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
            .onChange(of: selectedClubID) {
                if let id = selectedClubID {
                    path.append(.club(id))
                }
            }
        }
        .navigationTitle("Golf club selection")
        .navigationBarTitleDisplayMode(.inline)
    }
    
//    func note(_ club: ClubModel) -> String {
//        club.courses.flatMap(\.notes).joined(separator: "\n")
//    }
//    
//    func totalHoles(_ club: ClubModel) -> String {
//        let count = club.courses.reduce(0) { $0 + $1.holes.count }
//        return String(count)
//    }
}

//struct ClubRow: View {
//    let club: ClubModel
//    let provider: NomiProvider
//    
//    @State private var address = ""
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(club.name ?? "Unknown Club")
//            Text(address)
//        }
//        .task {
//            let place = await provider.reverse(lat: club.lat,lon: club.lng, options: NomiOptions())
//            let city = place.address?.city ?? ""
//            let state = place.address?.state ?? ""
//            address = city + state
//        }
//    }
//}
