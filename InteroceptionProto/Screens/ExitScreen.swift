//
//  ExitScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 20/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI

struct ExitScreen: View {
    var body: some View {
        ZStack {
            
            VStack {
                
                Text("Thank you for completing the task! Please let the experimenter know that you've finished.")
                .padding([.horizontal], UIUtils.defaultVPadding)
                .multilineTextAlignment(.center)
                
                Spacer().frame (height: 50)
                
                
                Spacer().frame (height: 50)
                Button(action: {
                    //self.showDetails.toggle()
                    // Logging.JLog(message: "pressed")
                    
                    guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSecxV1tfTjPIbVPf54SmIeMdAQVzy1f5qcWqPnghqFun_R9FA/viewform?usp=sf_link") else { return }
                    UIApplication.shared.open(url)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                          exit(0)
                         }
                    }
                    
                    
                }) {
                    Text("Exit")
                }
                .padding()
                .background(Color.red)
                    .font(.title)
                    .foregroundColor(.white)
                //.frame (width: 100, height: 50)
                Spacer().frame (height: 40)
                
            }
            
        }.navigationBarBackButtonHidden(true)
        
    }
}

struct ExitScreen_Previews: PreviewProvider {
    static var previews: some View {
        ExitScreen()
    }
}
