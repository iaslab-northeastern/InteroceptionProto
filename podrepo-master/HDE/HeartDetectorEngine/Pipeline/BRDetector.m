//
//  BRDetector.m
//  BreatingEngine
//
//  Created by Davide Morelli on 8/16/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "BRDetector.h"

@interface BRDetector()
{
    float currP;
    int passed;
    int currPh;
    BOOL slowSent;
    
    CMTime lastQualityUpdate;
    
    float currQuality;
    float currPhase;
    float lastQuality;
    float lastPhase;
    
    BOOL useAccelerometer;
    BOOL useCamera;
    
    float currPPGQuality;
    float currTachogramQuality;
    float currAccQuality;

    float currPPGPhase;
    float currTachogramPhase;
    float currAccPhase;
    
    BOOL PPGReady;
    BOOL AccelerometerReady;
    BOOL TachogramReady;

}

@end

@implementation BRDetector

@synthesize delegate = _delegate;
@synthesize breathQuality;

-(id)initWithCamera:(BOOL)usingCamera andAccelerometer:(BOOL)usingAccelerometer
{
    self = [super init];
    if (self) {
        useAccelerometer = usingAccelerometer;
        useCamera = usingCamera;
        [breathQuality removeAllObjects];
        lastQualityUpdate = CMTimeMake(0, 1);
    }
    return self;
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    if (ID == STREAM_PPG)
    {
        // breath phase?
        [_delegate breathingPhaseDetected:v withConfidence:lastQuality];
        return;
    }

    
    switch (ID) {
        case STREAM_PPG_QUALITY:
            // PPG
            currPPGQuality = v;
            PPGReady = YES;
            break;
        case STREAM_PPG_PHASE:
            currPPGPhase = v;
            break;
        case STREAM_ACCELEROMETER_QUALITY:
            // Accelerometer
            currAccQuality = v;
            AccelerometerReady = YES;
            break;
        case STREAM_ACCELEROMETER_PHASE:
            currAccPhase = v;
            break;
        case STREAM_TACHOGRAM_QUALITY:
            // Tachogram
            currTachogramQuality = v;
            TachogramReady = YES;
            break;
        case STREAM_TACHOGRAM_PHASE:
            currTachogramPhase = v;
            break;
            
        default:
            break;
    }
    
    // update quality and phase
//    float count = (AccelerometerReady ? 1.0 : 0.0) + (PPGReady ? 1.0 : 0.0) + (TachogramReady ? 1.0 : 0.0);
//    if (count > 0)
//    {
//        currQuality = (AccelerometerReady ? currAccQuality : 0.0) + (PPGReady ? currPPGQuality : 0.0) + (TachogramReady ? currTachogramQuality : 0.0);
//        currQuality = currQuality / count;
//    }
//    currPhase = (currPPGPhase + currTachogramPhase) / 2.0;
//    BOOL qualityReady = AccelerometerReady || PPGReady || TachogramReady;
    
    float count = (TachogramReady ? 1.0 : 0.0);
    if (count > 0)
    {
        currQuality = (TachogramReady ? currTachogramQuality : 0.0);
        currQuality = currQuality / count;
    }
    currPhase = currTachogramPhase;
    BOOL qualityReady = TachogramReady;
    
    
    
    if (qualityReady)
    {
        CMTime passedTime = CMTimeSubtract(t, lastQualityUpdate);
        // limit the rate
        if (CMTimeGetSeconds(passedTime) > 0.3)
        {
//            NSLog(@"---- currQuality: %f", currQuality);
            [_delegate performanceQuality:currQuality withTiming:currPhase];
            lastQualityUpdate = t;
        }
    }
    
    if( ID == STREAM_ACCELEROMETER_QUALITY)
    {
        [_delegate movementQuality:currAccQuality];
    }
    

}


- (void) addSampleForTime:(CMTime) t
                  withRed:(float) r
                withGreen:(float) g
                 withBlue:(float) b
{
//    passed++;
//    float passedP = ((float) passed) / 30.0;
//    if (passedP > currP)
//    {
//        if (!slowSent)
//        {
//            slowSent = YES;
//            [_delegate slowBreathingDetectedChanged:YES];
//        }
//        // trigger new period
//        currP = (8.0 + 5.0*((float)arc4random_uniform(100))/ 100.0)/4.0;
//        currPh = (currPh + 1) % 4;
//        passed = 0;
//        [_delegate breathingPhaseDetected:currPh withConfidence:1.0];
//        if (currPh == 0)
//        {
////            [_delegate breathingCycleDetectedWithInstantRate:currP*4.0 averageRate:currP*4.0 andQuality:1.0];
//  
//            // I tell the app how well the user is performing
//        }
//    }
//    [self fakeit];

}

- (void) addAccelerationForTime:(CMTime) t
                          withX:(float) x
                          withY:(float) y
                          withZ:(float) z
{
    // ignore
//    [self fakeit];
}

- (void)addControlSignalForTime:(CMTime)t withPhase:(float)p
{
    // ignore
//    [self fakeit];
}

//- (void)fakeit
//{
//    if (lastQualityUpdate == nil)
//    {
//        lastQualityUpdate = [NSDate date];
//    }
//    // limit the rate
//    if ([lastQualityUpdate timeIntervalSinceNow] < -0.3)
//    {
//        float fakeQ = (arc4random()%100)/100.0;
//        float fakeT = (arc4random()%100)/100.0 - 0.5;
//        [_delegate performanceQuality:fakeQ withTiming:fakeT];
//        lastQualityUpdate = [NSDate date];
//    }
//
//}



@end
