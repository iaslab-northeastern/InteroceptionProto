//
//  PDDataLogger.h
//  PulseDetector
//
//  Created by Andrea Canciani on 7/17/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRMSampleStreamAnalyzer.h"

@interface PDDataLogger : NSObject<HRMSampleStreamAnalyzer>
{
    NSString *filename;
    NSFileHandle *fileHandlerCsv;
}

- (void) startLogging;

- (void) stopLogging;

- (void) logBreathingPhase:(int) phase;

@end
