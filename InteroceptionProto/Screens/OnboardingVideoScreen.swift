//
//  OnboardingVideo1Screen.swift
//  
//
//  Created by Joel Barker on 16/02/2020.
//

import SwiftUI
import AVKit


final class OnboardingVideoModel: NSObject, ObservableObject {
    
    @Published var videoURL:URL?
    
}

struct OnboardingVideoScreen<Content, NextScreen>: View where Content: View, NextScreen: View {
    
    @ObservedObject var viewModal = OnboardingVideoModel()

    let content: Content
    let nextScreen: NextScreen
    
    @State var goBack = false
    
    init(_ videoName: String, @ViewBuilder content: () -> Content, @ViewBuilder nextScreen: () -> NextScreen) {

        self.content = content()
        self.nextScreen = nextScreen()
        
        self.viewModal.videoURL = Bundle.main.url(forResource: videoName, withExtension:"mp4")!
        if #available(iOS 14.0, *) {
            VideoPlayer(player: AVPlayer(url:  Bundle.main.url(forResource: videoName, withExtension: "mp4")!))
                
        } else {
            // Fallback on earlier versions
        }
        // Logging.JLog(message: "self.videoUrl : \(String(describing: self.viewModal.videoURL))")
    }
    
    
    var body: some View {
        
        VStack {
            
            //Spacer()
            
            VStack () {
                    HStack {
                        content.multilineTextAlignment(.center)
                        //Spacer ()
                    }
                .padding(.all, UIUtils.defaultVPadding)
                
            }.frame(height: 220)
                
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

struct OnboardingVideo1Screen: View {
    var body: some View {
        OnboardingVideoScreen("heart_beat_sound_out_sync", content: {
            Text("_onboardingvideo1_content")
        }, nextScreen: {
            OnboardingVideo2Screen ()
        })
    }
}

struct OnboardingVideo2Screen: View {
    var body: some View {
        OnboardingVideoScreen("heartbeats_in_sync", content: {
            Text("_onboardingvideo2_content")
        }, nextScreen: {
            OnboardingScreen4 ()
        })
    }
}
