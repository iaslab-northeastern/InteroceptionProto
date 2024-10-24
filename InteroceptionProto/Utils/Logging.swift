//
//  Logging.swift
//  Interoceptor
//
//  Created by Joel Barker on 02/07/2019.
//  Copyright © 2019 BioBeats. All rights reserved.
//

import Foundation

class Logging {
    
    class func JLog(message: String, functionName: String = #function, fileName: String = #file, lineNum: Int = #line) {
        
        //DDLogInfo ("\(fileName): \(functionName): \(lineNum):")
        NSLog ("\(fileName): \(functionName): \(lineNum): \(message)")
        
        //DDLogInfo("Info");
        
    }
    
}
