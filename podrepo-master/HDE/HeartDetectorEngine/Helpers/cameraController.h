//
//  cameraController.h
//  BioBeats
//
//  Created by Davide Morelli on 8/17/12.
//  Copyright (c) 2012 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

#import "HRMCameraDataDistiller.h"

#import "AccelerometerHelper.h"
#import "PDDataLogger.h"

#import "HREventsDelegate.h"

#import "StreamAnalyzer.h"

#import "HRDetector.h"

//#define LOGPERIODS 1
//#define LOGPULSEOXIMETER
//#define LOGTIME 1

/*
#define BUFFERLENGTH 64
#define BUFFERLENGTHOVER2 32
#define LOG2BUFFERLENGTH 6
#define LOG2BUFFERLENGTHOVER2 5
#define SAMPLFREQ 30
#define MINBPM 40.
#define MAXBPM 140.
#define MINQUALITY  0.3
#define SLOW_PERIODS 11
#define FAST_PERIODS 3
*/

@protocol PulseReceiver <NSObject>
@required
- (void) pulseReceived: (float) period;
@end

@interface cameraController : NSObject<HRMSampleStreamAnalyzer>
{
    // TO GET DATA ONLY
    AccelerometerHelper *accelerometer;
    PDDataLogger *logger;
    
    HRMCameraDataDistiller *cameraDistiller;
    id <PulseReceiver> delegate;

    dispatch_queue_t serialqueue;

    AVCaptureSession *session;
    AVCaptureDevice *device;
    float prev_sample;
    float r_avg;
    float g_avg;
    float b_avg;
    float rgb_avg;
    float *samples;
    float *diff;
    float *wAvgSamples;
    float quality;
    int currentArrayIndex;
    double prevSampleTime;
    
    float minDiff;
    float maxDiff;
    float currDiff;
    
    double duration;
    
    NSMutableArray *samplesHeart;
    NSMutableArray *samplesBPM;
    NSMutableArray *samplesDiff;
    NSMutableArray *periods;
    
//    COMPLEX_SPLIT   A;
//    FFTSetup        setupReal;
//    uint32_t        log2n;
//    uint32_t        n, nOver2;
//    int32_t         stride;
//    float           *originalReal, *obtainedReal, *binMagnitude;
//    float           *noiseRemoverWindow, *hanningWindow;
    float           *slowAvg, *fastAvg;
    float           *rateHistory;
    bool            dataReady;
    bool            *pulseHistory;
    int             firstPulse;
    int             secondPulse;
    float           *hrv;
    int             currentHrvIndex;
    BOOL            arraysAllocated;
    
    BOOL fingerPresent;
    BOOL cameraLocked;
    
    int BUFFERLENGTH;
    int BUFFERLENGTHOVER2;
    int LOG2BUFFERLENGTH;
    int LOG2BUFFERLENGTHOVER2;
    int SAMPLFREQ;
    int MINBPM;
    int MAXBPM;
    int MINQUALITY;
    int SLOW_PERIODS;
    int FAST_PERIODS;
    
    int lastSwitchTo2Index;
    float lastPeriod;
}

- (void) freeArrays;
- (float) getPeriod;
- (void) willResignActive;
- (void) didBecomeActive;
- (void) resetData;
- (id) initWithBestSampleFrequency;
- (NSArray *) getDiffBuffer;
- (NSArray *) getBPMBuffer;
- (NSArray *) getHeartBuffer;
- (NSArray *) getPeriods;
- (float *) getDiffFloats;
- (int) getCurrentArrayIndex;
- (float) getCurrDiff;
- (BOOL) getFingerPresent;
- (bool) getDataReady;
- (float) getQuality;
- (int) getSAMPLFREQ;
- (int) getBUFFERLENGTH;
- (int) getMINQUALITY;

- (void) lockCamera;

- (void) logBreathingPhase:(int) phase;


@property (retain, nonatomic) id<HREventsDelegate> hrdelegate;
@property (strong, nonatomic) id<HRMSampleStreamAnalyzer> streamdelegate;
@property (strong, nonatomic) id<StreamAnalyzer> pulseStreamDelegate;
@property BOOL fingerPresent;

@property HRDetector *hrDetector;

@property int framerate;

+ (BOOL) hasDualCamera;

@end
