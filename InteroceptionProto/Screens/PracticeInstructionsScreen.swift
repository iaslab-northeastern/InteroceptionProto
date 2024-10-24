//
//  PracticeInstructionsScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 28/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

class PracticeInstructionsViewModel: NSObject, ObservableObject {

    @Published var gotoTrial = false
}

struct PracticeInstructionsScreen: View {
    
    @ObservedObject private var viewModel = PracticeInstructionsViewModel()
    
    @State var goBack = false
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            VStack ()  {
                VStack {
                Text("_onboarding9_content")
                .padding(.all, UIUtils.defaultVPadding)
                .multilineTextAlignment(.center)
                
                }.frame(height: 300)
                
                HStack () {
                    
                    PopView(to: .backTwo, isActive: $goBack) {
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
                    
                    Button(action: {
                        self.viewModel.gotoTrial = true
                    }, label: {
                        Text("_onboarding_continue_button_label")
                    })
                    .buttonStyle(UIUtils.MyButtonNavStyle())
                    .cornerRadius(10)
                    .padding(.bottom, UIUtils.defaultVPadding)
                    
                    PushView(TrialScreen(), withId: "trialScreen", isActive: $viewModel.gotoTrial) {
                        Text("")
                    }
                    
                }.multilineTextAlignment(.center)
                
                
            }
        }
        .foregroundColor(Color.mainFgColor)
        .navigationBarBackButtonHidden(true)
        
    }
}

struct PracticeInstructionsScreen_Previews: PreviewProvider {
    static var previews: some View {
        PracticeInstructionsScreen()
    }
}
