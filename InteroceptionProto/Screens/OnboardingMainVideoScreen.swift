//
//  OnboardingMainVideoScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 16/02/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import AVKit

final class OnboardingMainVideoModel: NSObject, ObservableObject {
    
    @Published var videoURL:URL?
    
}

struct OnboardingMainVideoScreen<NextScreen>: View where NextScreen: View {
    
    @ObservedObject var viewModal = OnboardingMainVideoModel()
    
    let nextScreen: NextScreen
    
    @State var goBack = false
    
    init(_ videoName: String, @ViewBuilder nextScreen: () -> NextScreen) {
        
        self.nextScreen = nextScreen()
        
        self.viewModal.videoURL = Bundle.main.url(forResource: videoName, withExtension:"mp4")!
        
        // Logging.JLog(message: "self.videoUrl : \(String(describing: self.viewModal.videoURL))")
    }
    
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                PlayerContainerView(url: self.viewModal.videoURL!)
            }
            
            HStack () {
                
                PopView(isActive: $goBack) {
                    Text("")
                }
                
                Button(action: {
                    self.$goBack.wrappedValue = true
                }, label: {
                    Text("_button_back_label")
                })
                    .buttonStyle(UIUtils.MyButtonBackStyle())
                    .cornerRadius(10)
                    .padding(.bottom, UIUtils.defaultVPadding)
                
                
                Spacer ().frame(width: 60)
                
                PushView(nextScreen){
                    Text("_onboarding_continue_button_label")
                }
                .modifier(UIUtils.ButtonNavLabelStyle())
                .cornerRadius(10)
                .padding(.bottom, UIUtils.defaultVPadding)
                
            }.multilineTextAlignment(.center)
            
        }
        
        
        
    }
}

struct OnboardingMainVideo1Screen: View {
    var body: some View {
        OnboardingMainVideoScreen("video_for_MAD_task_final", nextScreen: {
            OnboardingImage1Screen ()
        })
    }
}
