//
//  ConfidenceRatingScreen.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 03/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI

private final class ConfidenceRatingScreenViewModel: ObservableObject {
    static let confidenceRange = ClosedRange<Double>(uncheckedBounds: (lower: 0, upper: 9))
    @Published var confidence = -1
    
    @Published var measureNotValid = false
    
    @Published var shouldGoToBodyParts = false
    
    @Published var theButtonText = "Confirm"
    
    @Published var showActivity = false
    
    @Published var flashNotWorking = false
    
    @Published var confidenceForSlider: Double { //double is needed for the slider
        didSet {
            confidence = Int(confidenceForSlider)
        }
    }
    
    init() {
        confidenceForSlider = .random(in: Self.confidenceRange)
        
    }
    
    func save() {
        // Logging.JLog(message: "confidence : \(confidence)")
        //save the _Int_ confidence
    }
    
    func registerForNotifications() {
        //NotificationCenter.default.addObserver(self, selector: #selector(start), name: UIApplication.willEnterForegroundNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(stop), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setButtonText (theText: String) {
        self.theButtonText = theText
    }
    
    @objc func start() {
        
        
        SyncroTaskManager.shared.taskDelegate = self
    }
}

// PRAGMA MARK: SyncroTaskManagerDelegate
extension ConfidenceRatingScreenViewModel: SyncroTaskManagerDelegate {
    
    func torchError () {
        self.flashNotWorking = false
    }
    
    func fingerPresentChanged(_ isPresent: Bool) {
        
        print("Finger is present: \(isPresent)")
        DispatchQueue.main.async {
            self.measureNotValid = !isPresent
        }
    }
    
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float) {
        
    }
    
    func newPPGSampleReady(_ sample: Float) {
        
    }
    
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float) {
        
    }
    
    
}

struct ConfidenceRatingScreen: View {
    @ObservedObject var interoceptionSettings: InteroceptionSettings
    
    @ObservedObject private var viewModel = ConfidenceRatingScreenViewModel()
    
    @State var showMannequin = false
    @State var goToFinalScreen = false
    @State var restartTrial = false
    
    @State var buttonText = "Confirm"
    @State var buttonContinueText = "Confirm"
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
           
            
            if viewModel.measureNotValid {
                FingerOverlay().transition(AnyTransition.opacity.animation(.easeOut(duration: 0.2)))
            }
            
            
            
            
            VStack {
                Text("_rating_screen_title")
                    .padding([.top, .horizontal] , UIUtils.defaultVPadding)
                    .multilineTextAlignment(.center)
                
                Spacer()
                ConfidenceSlider(confidenceForSlider: $viewModel.confidenceForSlider)
                Spacer()
                
                if self.$viewModel.showActivity.wrappedValue {
                    ProgressBar(width: 25, duration: 1,
                              backgroundColor: .background, color: .slider)
                    .frame(width: 100, height: 80, alignment: .center)
                }
                
                Button(action: {
                    
                    self.viewModel.save()

                    if self.interoceptionSettings.displayBodyPartsForCurrent() {
                        
                        self.showMannequin = true

                    } else if self.interoceptionSettings.isLastTrial() {
                        
                        
                        
                        SyncroTaskManager.shared.stop()
                        
                        self.goToFinalScreen = true
                        
                        ////self.showMannequin = true
                    } else {
                        
                        
                        
                        
                        if self.viewModel.theButtonText == "Confirm" {
                            // Logging.JLog(message: "changeButton")
                            self.viewModel.theButtonText = "Continue"

                        } else {
                            
                            
                            SyncroTaskManager.shared.stopAndRecordSyncro()
                            
                            //SyncroTaskManager.shared.torchCheck()
                            
                            
                            self.restartTrial = true
                            self.interoceptionSettings.next()
                        }
                        
                        
                    }
                }, label: {
                    Text("\(self.viewModel.theButtonText)")
                    
                })
                .buttonStyle(UIUtils.MyMutiButtonStyle())
                    .background(buttonColor.shadow(radius: 3))
                
                PushView(BodyPartsView(interoceptionSettings: self.interoceptionSettings), isActive: $showMannequin) {
                    Text("")
                }
                PushView(FinalScreen(), isActive: $goToFinalScreen){
                    Text("")
                }

                PushView(TrialScreen(), isActive: $restartTrial) {
                    Text("")
                }

                /*
                PopView(isActive: $restartTrial) {
                    Text("")
                }*/
            }
            .foregroundColor(.mainFgColor)
        }.alert(isPresented: $viewModel.flashNotWorking) {
            Alert(title: Text("Flash not working"), message: Text("The Flash doesn't appear to be working. Maybe the phone has over-heated...?"), dismissButton: .default(Text("Ok"), action: {
                self.$viewModel.flashNotWorking.wrappedValue = false
            })
            )
        }.onAppear {
            
            // Logging.JLog(message: "**** CONFIDENCE SCREEN ****")
            
            self.viewModel.registerForNotifications()
            self.viewModel.start()
            
            if !self.interoceptionSettings.displayBodyPartsForCurrent() {
                self.viewModel.theButtonText = "Confirm"
            }
            
        }
        .onDisappear {
            
            
            if self.viewModel.confidence == -1 {
                self.viewModel.confidence = Int (self.viewModel.confidenceForSlider)
            }

            // Logging.JLog(message: "InteroceptionSettings.practicesToGo : \(InteroceptionSettings.practicesToGo)")

            //SyncroTaskManager.shared.stop()
            
            // subsequent runs will be actual runs
             
            //if InteroceptionSettings.practicesToGo < 0 {
                
                // Logging.JLog(message: "recording confidence : \(self.viewModel.confidence)")
                
            //if !InteroceptionSettings.isPracticeRun {
                (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last!.confidence = self.viewModel.confidence
            //}
            
            let lastTask = (UIApplication.shared.delegate as! AppDelegate).dataset?.syncroTraining.last
            
            // Logging.JLog(message: "lastTask confidence : \(String(describing: lastTask?.confidence))")
            
            self.viewModel.showActivity = true
            
            (UIApplication.shared.delegate as! AppDelegate).dataset?.storeWithCompletion() { (errorStr: String) in

                self.viewModel.showActivity = false

                // Logging.JLog(message: "saveFinished : error : \(errorStr)")
            }
            
            
            
            InteroceptionSettings.practicesToGo -= 1

        }
    }
    
    var buttonColor: Color {
        return self.viewModel.theButtonText == "Confirm" ? .red : .green
    }
}

private struct ConfidenceSlider: View {
    private static let legendMaxWidth = CGFloat(130)
    @Binding var confidenceForSlider: Double
    
    var body: some View {
        VStack {
            Slider(value: $confidenceForSlider, in: ConfidenceRatingScreenViewModel.confidenceRange, step: 1)
            HStack {
                Text("_rating_screen_lowest_confidence")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: Self.legendMaxWidth, alignment: .leading)
                Spacer()
                Text("_rating_screen_highest_confidence")
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: Self.legendMaxWidth, alignment: .trailing)
            }
        }
        .padding()
    }
}

fileprivate struct FingerOverlay: View {
    var body: some View {
        ZStack {
            Color.bgColor
            VStack {
                Image("FingerOnCameraStandard")
                Text("_readjust_your_grip_title")
                    .font(.headline)
                Text("_readjust_your_grip_body")
                    .font(.footnote)
                    .padding()
            }
        }
        .zIndex(1)
    }
}

struct ConfidenceRatingScreen_Previews: PreviewProvider {
    static var previews: some View {
        ConfidenceRatingScreen(interoceptionSettings: InteroceptionSettings(numberOfTrials: 20, numberOfBodyParts: 5))
    }
}
