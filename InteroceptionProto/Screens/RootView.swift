//
//  RootView.swift
//  InteroceptionProto
//
//  Created by Matteo Puccinelli on 06/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStackView {
            
            // true start
            PartiIdScreen()
            
//            TrialScreen()
            
            //BaselineDataUseScreen ()
            //BaselineIntroUseScreen ()
            
            //BaselineInstructionsScreen ()
            //BaselineDataScreen ()
            
            //OnboardingImage2Screen()
            
            //OnboardingImage2Screen ()
            
            //PracticeInstructionsScreen ()
            
//            OnboardingVideo1Screen ()
//            OnboardingMainVideo1Screen ()
            
//            OnboardingVideoScreen ("heart_beat_sound_out_sync")
            
            //OnboardingScreen4
            
            //DataExportScreen()
            
            //ConfidenceRatingScreen(interoceptionSettings: InteroceptionSettings(numberOfTrials: 20, numberOfBodyParts: 5))
            
            //BodyPartsView (interoceptionSettings: InteroceptionSettings.init(numberOfTrials: 1, numberOfBodyParts: 1))
            
//            ExitScreen ()
//            FinalScreen ()
            
        }        
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
