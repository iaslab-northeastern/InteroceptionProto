//
//  OnboardingInfo1Screen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 29/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

class OnboardingInfo1ViewModel: NSObject, ObservableObject {

    @Published var goOn = false
}


struct OnboardingInfo1Screen: View {
    
    @ObservedObject private var viewModel = OnboardingInfo1ViewModel()
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            VStack {
                
                VStack () {
                    
                    Text("_onboarding3_content").frame(width: 350).multilineTextAlignment(.center)
                    //.padding(.all, UIUtils.defaultVPadding)
                    
                    //
                    
                    Image("onboardingPage3").resizable().scaledToFit().frame(width: 350)
                    
                }.frame(height: 500)
                
                
                
                
                //Spacer ()
                
                Button(action: {
                    self.viewModel.goOn = true
                }, label: {
                    Text("_onboarding_continue_button_label")
                })
                .buttonStyle(UIUtils.MyButtonContinueStyle())
                
                PushView(OnboardingInfo2Screen(), isActive: $viewModel.goOn) {
                    Text("")
                }
            }
        }
        .foregroundColor(Color.mainFgColor)
        .navigationBarBackButtonHidden(true)
        
    }
}

struct OnboardingInfo1Screen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingInfo1Screen()
    }
}
