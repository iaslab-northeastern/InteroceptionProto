//
//  Platform.swift
//  InteroceptionProto
//
//  Created by Joel Barker on 17/01/2020.
//  Copyright © 2020 BioBeats. All rights reserved.
//

struct Platform {
    static let isSimulator: Bool = {
        #if arch(i386) || arch(x86_64)
            return true
        #endif
        return false
    }()
}
