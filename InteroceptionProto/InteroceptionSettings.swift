//
//  InteroceptionSettings.swift
//  InteroceptionProto
//
//  Created by Matteo Vigoni on 06/12/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import UIKit
import Foundation

class InteroceptionSettings: ObservableObject{
    let numberOfTrials: Int
    let numberOfBodyParts: Int
    
    private var trials:Array<Bool>
    
    // first two runs are practices...
    public var currentIndex = -2
    
    // set to true so the first run will be a practice
    public static var isPracticeRun = true
    
    public static var practicesToGo = 1
    
    @Published var needForBodyParts = false
    
    init(numberOfTrials:Int, numberOfBodyParts:Int) {
        self.numberOfTrials = numberOfTrials
        self.numberOfBodyParts = numberOfBodyParts
        let mannequinEveryTrials = Int(numberOfTrials / numberOfBodyParts)
        
        //// Logging.JLog(message: "numRuns : \((UIApplication.shared.delegate as! AppDelegate).dataset!.numRuns!)")
        //self.currentIndex = (UIApplication.shared.delegate as! AppDelegate).dataset!.numRuns!
        
        if (UIApplication.shared.delegate as! AppDelegate).dataset?.numRuns != nil {
            
            // Logging.JLog(message: "self.currentIndex : \(self.currentIndex)")
            
            if self.currentIndex == -2 {
                // Logging.JLog(message: "setting currentIdx to : \((UIApplication.shared.delegate as! AppDelegate).dataset!.numRuns!)")
                self.currentIndex = (UIApplication.shared.delegate as! AppDelegate).dataset!.numRuns!
                
                InteroceptionSettings.practicesToGo = 0 - self.currentIndex
                
            }
            
            
        }
        
        trials = Array()
        while trials.count < numberOfTrials {
            trials.append((trials.count+1) % mannequinEveryTrials == 0)
        }
    }
    
    func next() {
        currentIndex += 1
        
        // Logging.JLog(message: "currentIndex : \(currentIndex)")
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.numRuns = currentIndex
        
        (UIApplication.shared.delegate as! AppDelegate).dataset?.store()
        
        // Logging.JLog(message: "(UIApplication.shared.delegate as! AppDelegate).dataset : \((UIApplication.shared.delegate as! AppDelegate).dataset?.toDictionary())")
        
        if currentIndex < 0 {
            needForBodyParts = false
        } else {
            needForBodyParts = trials[currentIndex]
        }
        
    }
    
    func displayBodyPartsForCurrent() -> Bool {
        
        
        guard currentIndex >= 0 else {
            return false
        }
        return trials[currentIndex]
        
        //return true
    }
    
    func isLastTrial() -> Bool {
        
        // Logging.JLog(message: "currentIndex : \(currentIndex), trials.count : \(trials.count)")

        return currentIndex == trials.count-1
        //return true
    }
}
