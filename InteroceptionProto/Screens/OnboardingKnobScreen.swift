//
//  OnboardingKnobScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 30/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

class OnboardingKnobViewModel: NSObject, ObservableObject {
    
    @Published var goOn = false
}


struct OnboardingKnobScreen: View {
    
    @ObservedObject private var viewModel = OnboardingKnobViewModel()
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            VStack {
                VStack {
                    Text("_onboarding6_content").frame(width: 350).multilineTextAlignment(.center)
                    //.padding(.all, UIUtils.defaultVPadding)
                    
                    //
                    
                    Image("knob_with_arrows").resizable().scaledToFit().frame(width: 279)
                    
                    //Spacer ()
                }.frame(height: 500)
                Button(action: {
                    self.viewModel.goOn = true
                }, label: {
                    Text("_onboarding_continue_button_label")
                })
                    .buttonStyle(UIUtils.MyButtonContinueStyle())
                
                PushView(OnboardingManScreen(), isActive: $viewModel.goOn) {
                    Text("")
                }
            }
        }
        .foregroundColor(Color.mainFgColor)
        .navigationBarBackButtonHidden(true)
        
    }
}

struct OnboardingKnobScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingKnobScreen()
    }
}
