//
//  HRMSampleStreamAnalyzer.h
//  HRMeter
//
//  Created by Andrea Canciani on 5/5/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol HRMSampleStreamAnalyzer <NSObject>

- (void) addSampleForTime:(CMTime) t
                  withRed:(float) r
                withGreen:(float) g
                 withBlue:(float) b;

- (void) addAccelerationForTime:(CMTime) t
                          withX:(float) x
                          withY:(float) y
                          withZ:(float) z;

- (void) addControlSignalForTime:(CMTime) t
               withPhase:(float) p;


@end
