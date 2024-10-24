//
//  PDDataTee.m
//  PulseDetector
//
//  Created by Andrea Canciani on 7/17/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "PDDataTee.h"

@implementation PDDataTee

@synthesize delegates;


- (void) addSampleForTime:(CMTime) t
                  withRed:(float) r
                withGreen:(float) g
                 withBlue:(float) b
{
    for (id<HRMSampleStreamAnalyzer> delegate in delegates) {
        @autoreleasepool {
            [delegate addSampleForTime:t withRed:r withGreen:g withBlue:b];
        }
    }
}

- (void) addAccelerationForTime:(CMTime) t
                          withX:(float) x
                          withY:(float) y
                          withZ:(float) z
{
    for (id<HRMSampleStreamAnalyzer> delegate in delegates) {
        @autoreleasepool {
            [delegate addAccelerationForTime:t withX:x withY:y withZ:x];
        }
    }
}

- (void) addControlSignalForTime:(CMTime) t
                       withPhase:(float) p
{
    for (id<HRMSampleStreamAnalyzer> delegate in delegates) {
        @autoreleasepool {
            [delegate addControlSignalForTime:t withPhase:p];
        }
    }
    
}

@end
