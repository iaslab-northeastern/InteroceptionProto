//
//  SwiftUIView.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 05/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI

struct GenericOnboardingScreen<Content, NextScreen>: View where Content: View, NextScreen: View {
    let content: Content
    let nextScreen: NextScreen
    
    @State var goBack = false
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder nextScreen: () -> NextScreen) {
        self.content = content()
        self.nextScreen = nextScreen()
    }
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
            VStack ()  {
                
                VStack () {
                        HStack {
                            content.multilineTextAlignment(.center)
                            //Spacer ()
                        }
                    .padding(.all, UIUtils.defaultVPadding)
                    
                }.frame(height: 520)
                
                
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
                    
                    PushView(nextScreen, withId: "onboarding"){
                                   Text("_onboarding_continue_button_label")
                               }
                    .modifier(UIUtils.ButtonNavLabelStyle())
                    .cornerRadius(10)
                    .padding(.bottom, UIUtils.defaultVPadding)
                    
                }.multilineTextAlignment(.center)
                
                
            }
            
            
            
           
            //
            //
        }
        .foregroundColor(Color.mainFgColor)
        .navigationBarBackButtonHidden(true)
    }
}

struct OnboardingScreen1: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding1_content")
        }, nextScreen: {
            OnboardingScreen2()
//            BaselineIntroScreen ()
        })
    }
}

struct OnboardingScreen2: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding2_content")
        }, nextScreen: {
//            OnboardingScreen3 ()
            // bringing baseline back, baby
            BaselineIntroUseScreen ()
        })
    }
}

struct OnboardingScreen3: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding3_content")
        }, nextScreen: {
            OnboardingVideo1Screen()
//            OnboardingInfo1Screen()
        })
    }
}

struct OnboardingScreen4: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding4_content")
        }, nextScreen: {
            OnboardingScreen5 ()
//            TrialScreen ()
        })
    }
}

struct OnboardingScreen5: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding5_content")
        }, nextScreen: {
            OnboardingMainVideo1Screen ()
        })
    }
}

struct OnboardingScreen6: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding6_content")
        }, nextScreen: {
//            BaselineIntroUseScreen ()
//            OnboardingScreen9()
            PracticeInstructionsScreen ()
        })
    }
}



struct OnboardingScreen7: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding7_content")
        }, nextScreen: {
            OnboardingScreen8()
        })
    }
}

struct OnboardingScreen8: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding8_content")
        }, nextScreen: {
            PracticeInstructionsScreen ()
//            BaselineIntroUseScreen ()
//            OnboardingScreen9()
        })
    }
}

// practice instructions screen
struct OnboardingScreen9: View {
    var body: some View {
        GenericOnboardingScreen(content: {
            Text("_onboarding9_content")
        }, nextScreen: {
            PracticeInstructionsScreen ()
        })
    }
}


struct PartiIdScreen: View {
    var body: some View {
        ParticipantIdScreen (content: {
            Text("_participantId")
        }, nextScreen: {
            OnboardingScreen1 ()
            //TrialScreen ()
//            FinalScreen ()
            
        })
    }
}


//struct BaselineInstructionsScreen: View {
//    var body: some View {
//        BaselineIntroScreen (content: {
//            Text("_baselineIntroduction")
//        }, nextScreen: {
//            BaselineDataScreen()
//        })
//    }
//}


struct DataExportScreen: View {
    var body: some View {
        ExportScreen (content: {
            Text("_dataExport")
        }, nextScreen: {
            PartiIdScreen()
        })
    }
}

struct OnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStackView {
            OnboardingScreen2()
        }
    }
}
