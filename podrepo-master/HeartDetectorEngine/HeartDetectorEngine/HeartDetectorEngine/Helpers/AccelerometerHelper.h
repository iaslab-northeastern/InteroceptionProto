//
//  AccelerometerHelper.h
//  PulseDetector
//
//  Created by Davide Morelli on 7/18/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "HRMSampleStreamAnalyzer.h"

@interface AccelerometerHelper : NSObject<HRMSampleStreamAnalyzer>

@property (strong, nonatomic) id<HRMSampleStreamAnalyzer> delegate;

- (instancetype) initWithCMMotionManager: (CMMotionManager *) motionManager;

- (void) startAccelerometer;

- (void) stopAccelerometer;

@end
