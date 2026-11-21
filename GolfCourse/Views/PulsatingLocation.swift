//
//  PulsatingLocation.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/21.
//
import SwiftUI
import MapKit


struct PulsatingLocation: View {

    @State private var pulse = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 2.0) / 2.0
            
            ZStack {
                Canvas { context, size in
                    let progress = phase
                    let radius = 17.5 + (17.5 * progress)
                    let opacity = 0.8 * (1.0 - progress)
                    
                    let rect = CGRect(
                        x: size.width / 2 - radius,
                        y: size.height / 2 - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.blue.opacity(opacity)),
                        lineWidth: 3
                    )
                }
                .frame(width: 60, height: 60)
                
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.blue)
                    .shadow(color: .white, radius: 8)
                    .shadow(color: .white, radius: 4)
                    .shadow(radius: 3)
            }
        }
    }
}

