//
//  BaselineIntroScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 24/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct BaselineIntroScreen<NextScreen>: View where NextScreen: View {
    
    @State private var gotoNext: Int? = nil
    
    @State var goBack = false
    
    let nextScreen: NextScreen
    
    init(@ViewBuilder nextScreen: () -> NextScreen) {

        self.nextScreen = nextScreen()
    }
    
    var body: some View {
        ZStack {
            
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                VStack {
                    Spacer ().frame(height: 10)
                    
                    HStack(alignment: .center) {
                        
                        VStack () {
                            Image("FingerOnCameraStandard")
                            Text("Getting ready to check your heartbeat").frame (width: 320)
                            Text("\nWe will shortly turn on the LED Flash and camera on this phone, and will use it to take your heart rate. Please place your index finger across both camera and flash.")
                                .frame (width: 320)
                                .font(.system(size: 13))
                            
                            
                            
                        }
                        
                        
                        
                        
                        
                    }
                    Spacer().frame(height: 30)
                    
                    NavigationLink(destination: BaselineDataUseScreen(), tag: 1, selection: $gotoNext) {
                        return Text("")
                    }
                }.frame(height: 500)
                
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
                }
                
                Spacer ()
            }
        }
        
    }
    
}

struct BaselineIntroScreen_Previews: PreviewProvider {
    
    @available(iOS 13.0.0, *)
    static var previews: some View {
        BaselineIntroScreen(nextScreen: {
            BaselineDataUseScreen ()
        })
    }
}

struct BaselineIntroUseScreen: View {
    @available(iOS 13.0.0, *)
    var body: some View {
        BaselineIntroScreen(nextScreen: {
            BaselineDataUseScreen ()
        })
    }
}
