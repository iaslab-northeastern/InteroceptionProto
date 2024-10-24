//
//  ParticipantIdScreen.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 17/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

import SwiftUI
import UIKit

final class ParticipantIdModel: NSObject, ObservableObject {
    
    @Published var partiId = ""
    
    @Published var haveData = false
    
    @Published var showActivity = true
    
}

struct ParticipantIdScreen<Content, NextScreen>: View where Content: View, NextScreen: View {
    let content: Content
    let nextScreen: NextScreen
    
    @ObservedObject var partiViewModel = ParticipantIdModel()
    
    @State private var havePartiId = false
    
    
    
    //@State private var partiId: String = ""
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder nextScreen: () -> NextScreen) {
        self.content = content()
        self.nextScreen = nextScreen()
        
        // for testing...
        //InteroceptionDataset.wipePreviousData()
        
        let previousData = InteroceptionDataset.hasPreviousData()
        
        // Logging.JLog(message: "previousData : \(previousData)")
        
        let dataset = InteroceptionDataset()
        
        (UIApplication.shared.delegate as! AppDelegate).dataset = dataset;
        
        self.partiViewModel.haveData = previousData
        
    }
    
    var body: some View {
        
        
        
        
        ZStack {
            
            
            
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            VStack {
                
                
                
                Spacer ().frame(height: 50)
                    content
                Spacer ()
                    .frame(height: 150.0)
                HStack(alignment: .center) {
                    TextField("ParticipantId", text: $partiViewModel.partiId, onCommit: {() in
                        
                        // Logging.JLog(message: "idis : \(self.$partiViewModel.partiId)")
                        
                        if self.$partiViewModel.partiId.wrappedValue != "" {
                            self.$havePartiId.wrappedValue = true
                        }
                        
                    })
                        .frame(width: 170.0)
                        
                        //.frame(height: 200.0)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                    .padding(.all, UIUtils.defaultVPadding)
                }
                
                
                
                    
                
                ActivityIndicatorView(isShowing: $partiViewModel.showActivity) {
                                   NavigationView {
                                       Text("")
                                           //.navigationBarTitle(Text("List"), displayMode: .large)
                                   }
                               }
                
                Spacer ().frame (height: 200)
                
               
                
                PushView(nextScreen){
                    Text("_onboarding_continue_button_label")
                }
                .modifier(UIUtils.ButtonContinueLabelStyle())
                .cornerRadius(10)
                .padding(.bottom, UIUtils.defaultVPadding)
                .disabled(!havePartiId)
            
                
            }
        .alert(isPresented: $partiViewModel.haveData) {
                Alert(title: Text("Previous Run Found"), message: Text("Data from a previous run was found on this device. Should this data be re-used...?"), primaryButton: .default(Text("Yes"), action: {
                    
                    // Logging.JLog(message: "yes clicked")
                    (UIApplication.shared.delegate as! AppDelegate).dataset = InteroceptionDataset.load()
                    
                    self.$partiViewModel.partiId.wrappedValue = (UIApplication.shared.delegate as! AppDelegate).dataset!.participantID
                    self.$havePartiId.wrappedValue = true
                    
                    
                }), secondaryButton: .default(Text("No"), action: {
                    // Logging.JLog(message: "no clicked")
                })
                )
            }
        }.onAppear() {
            
            // Logging.JLog(message: "disableSleep")
            UIApplication.shared.isIdleTimerDisabled = true
            
            UserManager.shared.loginOrSignUpAnon () { (errorStr: String) in
                
                self.partiViewModel.showActivity = false
                
                // Logging.JLog(message: "errorStr : \(errorStr)")
            }
            
            // enable this to get all csv data
            //self.partiViewModel.getAllUsers()
            
        }.onDisappear() {
            // Logging.JLog(message: "onDisappear")
            print (self.$partiViewModel.partiId)
            
            // Logging.JLog(message: "self.$partiViewModel.partiId.wrappedValue : \(self.$partiViewModel.partiId.wrappedValue)")
            (UIApplication.shared.delegate as! AppDelegate).dataset?.participantID = self.$partiViewModel.partiId.wrappedValue
            
            if UserManager.me != nil {
                (UIApplication.shared.delegate as! AppDelegate).dataset?.uuid = UserManager.me!.uuid
                // Logging.JLog(message: "storing uuid : \(UserManager.me?.uuid)")
            }
            
            
            (UIApplication.shared.delegate as! AppDelegate).dataset?.store()
            
            (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion () { (errorStr: String) in
                
                // Logging.JLog(message: "saveFinished")
            }
            
            
            // Logging.JLog(message: "(UIApplication.shared.delegate as! AppDelegate).dataset : \((UIApplication.shared.delegate as! AppDelegate).dataset?.toDictionary())")
            
// Logging.JLog(message: "InteroceptionDataset.load()?.toDictionary()2 : \(InteroceptionDataset.load()?.toDictionary())")
            
        }
        .foregroundColor(Color.mainFgColor)
    }
}

extension ParticipantIdModel {
    
    func getAllUsers () {
        
        // Logging.JLog(message: "getAllUsers")
        
        UserDetails.shared.getAllUuids() { (uuids: [String : InteroceptionDataset], errorStr: String) in
            
            //// Logging.JLog(message: "uuids : \(uuids)")
            
            // Logging.JLog(message: "uuids.count : \(uuids.count)")
            
            for (uuid, dataSet) in uuids {
                
                //// Logging.JLog(message: "uuid : \(uuid)")

                print ("--------------------------------")

                
                print ("UUID : \(uuid)\n")
                
                //// Logging.JLog(message: "dataSet.toCSV()")
                
                print (dataSet.toCSV())
                
                print ("--------------------------------")

            }
            
        }
    }
    
}

struct ParticipantIdScreen_Previews: PreviewProvider {
    static var previews: some View {
        
        ParticipantIdScreen(content: {
            Text("_participantId")
        }, nextScreen: {
            HowToScreen()
        })
        
    }
}
