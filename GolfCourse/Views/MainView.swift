//
//  MainView.swift
//  GolfCourse
//
//  Created by Ringo Wathelet on 2026/11/21.
//
//import SwiftUI
//import AuthenticationServices
//import FirebaseAuth
//
//
//struct MainView: View {
//    @Environment(AuthModel.self) private var auth
//    @Environment(ChatService.self) private var chatService
//    @Environment(SittingService.self) private var sittingService
//    @Environment(ColorsModel.self) var colorsModel
//    
//    var body: some View {
//        ZStack {
//            colorsModel.backColor.ignoresSafeArea()
//            
//            VStack {
//                Group {
//                    switch auth.state {
//                        case .checkingAuthentication: ProgressView()
//                        case .signedOut: LoginView()
//                        case .waitingForApproval: WaitingApprovalView()
//                        case .signedIn(let user): MainView(user: user)
//                      //  case .admin(let user): AdminMainView(user: user)
//                    }
//                }
//            }
//        }
//    }
//}
