//
//  OnboardingManScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 30/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

import SwiftUI

class OnboardingManViewModel: NSObject, ObservableObject {
    
    @Published var goOn = false
}


struct OnboardingManScreen: View {
    
    @ObservedObject private var viewModel = OnboardingManViewModel()
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                VStack {
                    Text("_onboarding7_content").frame(width: 350).multilineTextAlignment(.center)
                    //.padding(.all, UIUtils.defaultVPadding)
                    
                    //
                    
                    Image("mannequin_coloured").resizable().scaledToFit().frame(width: 350)
                }.frame(height: 550)
                
                //Spacer ()
                
                Button(action: {
                    self.viewModel.goOn = true
                }, label: {
                    Text("_onboarding_continue_button_label")
                })
                    .buttonStyle(UIUtils.MyButtonContinueStyle())
                
                PushView(OnboardingScreen8 (), isActive: $viewModel.goOn) {
                    Text("")
                }
            }
        }
        .foregroundColor(Color.mainFgColor)
        .navigationBarBackButtonHidden(true)
        
    }
}


struct OnboardingManScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingManScreen()
    }
}
