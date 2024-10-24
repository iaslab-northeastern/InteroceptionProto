//
//  Utility.swift
//  AVPlayer-SwiftUI
//
//  Created by Chris Mash on 11/09/2019.
//  Copyright © 2019 Chris Mash. All rights reserved.
//

import Foundation

class Utility: NSObject {
    
    private static var timeHMSFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
    
    static func formatSecondsToHMS(_ seconds: Double) -> String {
        
        // Logging.JLog(message: "seconds : \(String(describing: seconds))")
        
        let d = Double.nan
        
        if seconds == Double.nan {
            // Logging.JLog(message: "nan!!!")
            return "00:00"
        }
        
        return timeHMSFormatter.string(from: seconds) ?? "00:00"
        
        
    }
    
}
