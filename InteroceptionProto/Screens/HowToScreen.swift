//
//  HowToScreen.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 06/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI
import HeartDetectorEngine

class HowToScreenViewModel: NSObject, ObservableObject {
    private static let baselineDuration = Int32(10)
    private let engine = HeartDetectorEngine()
    @Published var gotoTrial = false
    
    func startMonitoring() {
        engine.hrDelegate = self
        engine.startHeartEngineSavingRawCameraSamples(false, forDuration: Self.baselineDuration)
    }
    
    private func stopMonitoring() {
        engine.stop()
        engine.hrDelegate = nil
    }
}

extension HowToScreenViewModel: HREventsDelegate {
    func fingerPresentChanged(_ isPresent: Bool) {
        if isPresent {
            DispatchQueue.main.async {
                self.stopMonitoring()
                self.gotoTrial = true
            }
        }
    }
    func beatDetected(withInstantBPM instantBPM: Float, andAverageBPM averageBPM: Float) {        
        //nothing to do
    }
    func newPPGSampleReady(_ sample: Float) {
        //nothing to do
    }
    func reportHRVActivation(_ activation: Float, withMaxPeriod max: Float, andMinPeriod min: Float) {
        //nothing to do
    }
}

struct HowToScreen: View {
    @ObservedObject private var viewModel = HowToScreenViewModel()
    
    var body: some View {
        ZStack {
            Color.bgColor
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("_how_to_title").multilineTextAlignment(.center)
                Spacer()
                Image("FingerOnCameraStandard")
                    .aspectRatio(contentMode: .fit)
                Spacer()
                Text("_how_to_body1").multilineTextAlignment(.center)
                Text("_how_to_body2")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                    .multilineTextAlignment(.center)
                
                //PushView(TrialScreen(), withId: "trialScreen", isActive: $viewModel.gotoTrial) {
                PushView(PracticeInstructionsScreen(), isActive: $viewModel.gotoTrial) {
                    Text("")
                }
            }
            .padding(.all, UIUtils.defaultVPadding)
            .onAppear {
                self.viewModel.startMonitoring()
            }
        }
        .foregroundColor(.mainFgColor)
    }
}

struct HowToScreen_Previews: PreviewProvider {
    static var previews: some View {
        HowToScreen()
    }
}
