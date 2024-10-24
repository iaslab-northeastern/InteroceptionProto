//
//  AccelerometerHelper.m
//  PulseDetector
//
//  Created by Davide Morelli on 7/18/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//
#import "AccelerometerHelper.h"
#import <CoreMotion/CoreMotion.h>

@interface AccelerometerHelper()
{
}

@property (strong, nonatomic) CMMotionManager *motionManager;
@end

@implementation AccelerometerHelper

@synthesize delegate = _delegate;

- (instancetype)initWithCMMotionManager:(id)motionManager
{
    self = [super init];
    if (self)
    {
        _motionManager = motionManager;
    }
    return self;
}

//- (CMMotionManager *)motionManager
//{
//    CMMotionManager *motionManager = nil;
//    id appDelegate = [UIApplication sharedApplication].delegate;
//    if ([appDelegate respondsToSelector:@selector(motionManager)]) {
//        motionManager = [appDelegate motionManager];
//    }
//    return motionManager;
//}

- (void)startAccelerometer
{
    
    // 10 Hz hardcoded
    self.motionManager.accelerometerUpdateInterval = 1.0/10.0;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                             withHandler:^(CMAccelerometerData *data, NSError *error) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     
                                                     float ax, ay, az;
                                                     ax = data.acceleration.x;
                                                     ay = data.acceleration.y;
                                                     az = data.acceleration.z;
                                                     NSTimeInterval timestamp = data.timestamp;
                                                     //NSTimeInterval timestamp = boottime + data.timestamp;
                                                     CMTime t = CMTimeMakeWithSeconds(timestamp, 1000);
                                                     [_delegate addAccelerationForTime:t withX:ax withY:ay withZ:az];
//                                                     NSLog(@"accelerometer %f", timestamp);
                                                 });
                                             }];
    
    
}

-(void)stopAccelerometer
{
    [self.motionManager stopAccelerometerUpdates];
}

@end
