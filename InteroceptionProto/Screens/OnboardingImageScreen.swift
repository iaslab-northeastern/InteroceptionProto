//
//  OnboardingImageScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 16/02/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import AVKit

final class OnboardingImageModel: NSObject, ObservableObject {
    
    @Published var imageName = ""
    
    @Published var textHeight = CGFloat ()

}

struct OnboardingImageScreen<Content, NextScreen>: View where Content: View, NextScreen: View {
    
    @ObservedObject var viewModal = OnboardingImageModel()

    let content: Content
    let nextScreen: NextScreen
    
    @State var goBack = false

    init(_ imgName: String, txtHeight: CGFloat, @ViewBuilder content: () -> Content, @ViewBuilder nextScreen: () -> NextScreen) {

        self.content = content()
        self.nextScreen = nextScreen()
        
        self.viewModal.imageName = imgName
        self.viewModal.textHeight = txtHeight
        
        // Logging.JLog(message: "self.imageName : \(String(describing: self.viewModal.imageName))")
    }

    var body: some View {
        
        VStack {
            
            //Spacer()
            
            VStack () {
                    HStack {
                        content.multilineTextAlignment(.center)
                        //Spacer ()
                    }
                //.padding(.all, UIUtils.defaultVPadding)
                
            }.frame(height: $viewModal.textHeight.wrappedValue)
                
            HStack {
                
                Image($viewModal.imageName.wrappedValue).resizable().scaledToFit().frame(width: 279)
                
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

struct OnboardingImage1Screen: View {
    var body: some View {
        OnboardingImageScreen("confidence_screenshot", txtHeight: 160, content: {
            Text("_onboardingimage1_content")
        }, nextScreen: {
            OnboardingImage2Screen ()
        })
    }
}

struct OnboardingImage2Screen: View {
    var body: some View {
        OnboardingImageScreen("mannequin_coloured", txtHeight: 230, content: {
            Text("_onboardingimage2_content")
        }, nextScreen: {
            OnboardingScreen6 ()
        })
    }
}

