//
//  DetectorsPipelineBuilder.m
//  BreatingEngine
//
//  Created by Davide Morelli on 8/16/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "HeartDetectorEngine.h"
#import "HRDetector.h"
#import "BRDetector.h"
#import "cameraController.h"
#import "PDDataTee.h"
#import "PDDataLogger.h"
#import "AccelerometerHelper.h"
#import "Downsampler.h"
#import "MakeUniformTime.h"
#import "StreamLogger.h"
#import "BufferedFunctions.h"
#import "PipelineStageToStream.h"
#import "StreamTee.h"
#import "CrossCorrelation.h"
#import "DiscardHead.h"
#import "Collector.h"

// to fix CMTimes see http://stackoverflow.com/questions/7576017/nstimeinterval-to-unix-timestamp

@interface HeartDetectorEngine()
{
}
@property     BRDetector *brDetector;
@property     HRDetector *hrDetector;
@property     PDDataLogger *logger;
@property     cameraController *camera;
@property     AccelerometerHelper *accelerometer;
@property     NSDate *devStartTime;
@property     PipelineStageToStream *converter;
@property     Collector *PPGCollector;

@property     MakeUniformTime *uniformTachogramExternalDetector;


@end

@implementation HeartDetectorEngine
{
    BOOL savePPGSamples;
}

@synthesize HRDelegate = _HRDelegate;
@synthesize BRDelegate = _BRDelegate;

@synthesize brDetector = _brDetector;
@synthesize hrDetector = _hrDetector;
@synthesize logger = _logger;
@synthesize camera = _camera;
@synthesize accelerometer = _accelerometer;
@synthesize devStartTime = _devStartTime;
@synthesize converter = _converter;
@synthesize PPGCollector = _PPGCollector;

- (void)startBreathEngineWithCMMotionManager:(id)motionManager andCamera:(BOOL)cameraPresent andControlSignalPeriod:(float)period saveRawCameraSamples:(BOOL)saveRawPPG forDuration:(int)seconds

{
    savePPGSamples = saveRawPPG;
    // during initialisation
    // Get NSTimeInterval of uptime i.e. the delta: now - bootTime
    NSDate *startTime = [NSDate date];
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;    
    // Now since dev start
    self.devStartTime = [startTime dateByAddingTimeInterval:-uptime];
    
    // NO ARC?!?!?!
//    [self.devStartTime retain];
    
    // build the pipeline:
    // camera is both a stage of the pipeline and the HRDetector, this has to change
    // camera and accelerometer go into tee
    // tee goes to logger and brDetector
    int framerate = 30;
    if (cameraPresent)
    {
        self.camera = [[cameraController alloc] initWithBestSampleFrequency];
        framerate = self.camera.framerate * 2.0;
        //camera.hrdelegate = _HRDelegate;
    }
    self.samplerate = self.camera.framerate;
    if (saveRawPPG)
        self.PPGCollector = [[Collector alloc] initWithSize:self.camera.framerate*seconds];

//    NSLog(@"camera framerate set to = %d", framerate);
    //logger = [[PDDataLogger alloc] init];
    BOOL accelerometerPresent = NO;
    if (motionManager)
    {
        accelerometerPresent = YES;
        self.accelerometer = [[AccelerometerHelper alloc] initWithCMMotionManager:motionManager];
    }
    
    self.brDetector = [[BRDetector alloc] initWithCamera:cameraPresent andAccelerometer:accelerometerPresent];
    self.brDetector.delegate = _BRDelegate;
    
    int samplesForLPFilterPPG = 30;
    int delayLPFilterPPG = samplesForLPFilterPPG/2;
    int samplesForDetrendPPG = 30;
    int samplesForNormPPG = 60;

    int samplesForLPFilterTachgoram = 30;
    int samplesForDetrendTachgoram = 30;
    int samplesForNormTachgoram = 60;

    int samplesForLPFilterACC = 30;
    int delayLPFilterACC = samplesForLPFilterACC/2;
    int samplesForDetrendACC = 30;
    int samplesForNormACC = 60;
    int samplePeriod = period * 10;
    int samplesForCorrelation = powf(2, ceilf(log(samplePeriod)/log(2.0)));
    int downsamplingFactor = framerate/10;
    int sumslopeSize = (int) (framerate * 0.128 + 0.5);
    int wabpSize = framerate * 2;
    
    // how many samples of the control signal we have to discard to ensure it's in synch with tachogram
    int samplesForDiscardHeadTachogram = 0.128 * 10 + 2*10 + samplesForDetrendTachgoram + samplesForNormTachgoram;

    
    self.hrDetector = [[HRDetector alloc] initWithPeriod:period];
    self.converter = [[PipelineStageToStream alloc] init];
    
    self.hrDetector.delegate = self.HRDelegate;

    // ------------------ breathing detector ------------------
    // PPG
    Downsampler *downsamplerPPG = [[Downsampler alloc] initWithDownsamplingFactor:downsamplingFactor];
    BufferedFunctions *avgmidPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:samplesForLPFilterPPG];
    BufferedFunctions *detrendendPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendPPG];
    BufferedFunctions *normalizerPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormPPG];
    BufferedFunctions *inverterPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *delayControl = [[BufferedFunctions alloc] initWithType:BUFFERED_DELAY andSize:delayLPFilterPPG];
    StreamTee *teeCleanPPG = [[StreamTee alloc] init];
    StreamTee *teeControlSignal = [[StreamTee alloc] init];
    StreamTee *teeControlSignalDelayed = [[StreamTee alloc] init];
    StreamTee *teePPG = [[StreamTee alloc] init];
    CrossCorrelation *correlationPPG = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationPPG.producedCorrelationStreamID = STREAM_PPG_QUALITY;
    correlationPPG.producedPhaseStreamID = STREAM_PPG_PHASE;

    // Tachogram
    BufferedFunctions *normalizerTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormTachgoram];
    BufferedFunctions *inverterTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    MakeUniformTime *uniformTachogram = [[MakeUniformTime alloc] initWithSamplerate:10.0]; // breathing engine fixed at 10Hz
    MakeUniformTime *uniformPPG = [[MakeUniformTime alloc] initWithSamplerate:framerate]; // ensure the HR engine has uniform data
    MakeUniformTime *uniformPPGForDisplay = [[MakeUniformTime alloc] initWithSamplerate:30]; // display at 30 hz
    StreamTee *teeTachogram = [[StreamTee alloc] init];
    BufferedFunctions *detrendendTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendTachgoram];
    CrossCorrelation *correlationTachogram = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationTachogram.producedCorrelationStreamID = STREAM_TACHOGRAM_QUALITY;
    correlationTachogram.producedPhaseStreamID = STREAM_TACHOGRAM_PHASE;
    DiscardHead *discardHeadTachogram = [[DiscardHead alloc] initWithSize:samplesForDiscardHeadTachogram];

    // Accelerometer
    CrossCorrelation *correlationACC = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationACC.producedCorrelationStreamID = STREAM_ACCELEROMETER_QUALITY;
    correlationACC.producedPhaseStreamID = STREAM_ACCELEROMETER_PHASE;
    BufferedFunctions *avgmidACC = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:samplesForLPFilterACC];
    BufferedFunctions *detrendendACC = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendACC];
    BufferedFunctions *normalizerACC = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormACC];
    
    // HR
    int lopSize = framerate/15;
    BufferedFunctions *lop = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:lopSize];
    BufferedFunctions *invertCamera = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *sumslope = [[BufferedFunctions alloc] initWithType:BUFFERED_SUM_SLOPE_FUNCTION andSize:sumslopeSize]; // 8 ~ 60*0.128
    BufferedFunctions *wabp = [[BufferedFunctions alloc] initWithType:BUFFERED_WABP andSize:wabpSize];
    
    self.camera.hrDetector = self.hrDetector;
    self.camera.streamdelegate = self.converter;
    self.converter.controlSignalDelegate = teeControlSignal;
    teeControlSignal.delegates = @[delayControl , discardHeadTachogram ];
    discardHeadTachogram.delegate = correlationTachogram;
    delayControl.delegate = teeControlSignalDelayed;
    teeControlSignalDelayed.delegates = @[correlationPPG, correlationACC /*, [[StreamLogger alloc] initWithName:@"control" ] */ ];

    if (saveRawPPG)
    {
        self.converter.cameraDelegate = [[StreamTee alloc] initWithDelegates:@[lop, self.PPGCollector]];
    } else
    {
        self.converter.cameraDelegate = lop;
    }
    lop.delegate = teePPG;
    teePPG.delegates = @[
                         downsamplerPPG
                         , uniformPPG
                         , uniformPPGForDisplay
                         //                         , [[StreamLogger alloc] initWithName:@"rawcamera"]
                         ];
    uniformPPGForDisplay.delegate = self;
    uniformPPG.delegate = invertCamera;
    downsamplerPPG.delegate = avgmidPPG;
    avgmidPPG.delegate = detrendendPPG;
    detrendendPPG.delegate = normalizerPPG;
    normalizerPPG.delegate = inverterPPG;
    inverterPPG.delegate = teeCleanPPG;
    teeCleanPPG.delegates = @[
                              correlationPPG
                              , self.brDetector ,
                              /*[[StreamLogger alloc] initWithName:@"PPG" ] */
                              ];
    invertCamera.delegate = sumslope;
//    invertCamera.delegate = [[StreamTee alloc] initWithDelegates: @[
//                                                                    sumslope
////                                                                    , [[StreamLogger alloc] initWithName:@"cameraForSSF"]
//                                                                    ]];
    sumslope.delegate = wabp;
//    sumslope.delegate = [[StreamTee alloc] initWithDelegates: @[
//                                                                wabp
////                                                                , [[StreamLogger alloc] initWithName:@"SSF"]
//                                                                ]];


    self.accelerometer.delegate = self.converter;
    self.converter.accelerometerDelegate = avgmidACC;
    avgmidACC.delegate = detrendendACC;
    detrendendACC.delegate = normalizerACC;
    normalizerACC.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                    correlationACC
//                                                                    , [[StreamLogger alloc] initWithName:@"Accelerometer" ]
                                                                    ]];
    
//    camera.pulseStreamDelegate = uniformTachogram;
    wabp.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                           uniformTachogram
                                                           , self.hrDetector
//                                                           , [[StreamLogger alloc] initWithName:@"wabp"]
                                                           ]];
    
//    uniformTachogram.delegate = detrendendTachogram;
    uniformTachogram.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                       detrendendTachogram
//                                                                       , [[StreamLogger alloc] initWithName:@"uniformTachogram"]
                                                                       ]];
    detrendendTachogram.delegate = normalizerTachogram;
    normalizerTachogram.delegate = inverterTachogram;
    inverterTachogram.delegate = teeTachogram;
//    camera.pulseStreamDelegate = teeTachogram;
    teeTachogram.delegates = @[
                               correlationTachogram
//                               , [[StreamLogger alloc] initWithName:@"tachogramForCorrelation" ]
                               ];
    
    correlationTachogram.delegateCorrelation = [[StreamTee alloc] initWithDelegates: @[
                                                                                       self.brDetector
//                                                                                       , [[StreamLogger alloc] initWithName:@"tachogramCorr"]
                                                                                       ]];
    correlationTachogram.delegatePhase = self.brDetector;
    correlationPPG.delegateCorrelation =  [[StreamTee alloc] initWithDelegates: @[
                                                                                  self.brDetector
//                                                                                  , [[StreamLogger alloc] initWithName:@"PPGCorrelation" ]
                                                                                  ]];
    correlationPPG.delegatePhase = self.brDetector;
    correlationACC.delegateCorrelation = [[StreamTee alloc] initWithDelegates: @[
                                                                                 self.brDetector
//                                                                                 , [[StreamLogger alloc] initWithName:@"AccCorrelation" ]
                                                                                 ]];
    correlationACC.delegatePhase = self.brDetector;
    
    // start the pipeline
//    [logger startLogging];
    [_camera resetData];
    [_camera didBecomeActive];
    [_accelerometer startAccelerometer];
}

- (void) stop
{
    // stop the pipeline
    [_camera willResignActive];
    [_accelerometer stopAccelerometer];
//    [logger stopLogging];
    
    // destroy the pipeline
    self.camera = nil;
    self.logger = nil;
    self.accelerometer = nil;
    self.brDetector = nil;
    self.converter = nil;
    self.hrDetector = nil;
}

-(void)addControlSignalValue:(float)v
{
    // generate a CMTime timestamp
    NSTimeInterval secondsSinceStart = -[self.devStartTime timeIntervalSinceNow];
    CMTime t = CMTimeMake(secondsSinceStart, 1000);
    [self addControlSignalValue:v andTime:t];
    //NSLog(@"control signal %f", v);

}

- (void) addControlSignalValue:(float)v andTime:(CMTime)t
{
    // generate a CMTime timestamp
    [_brDetector addControlSignalForTime:t withPhase:v];
    [_converter addControlSignalForTime:t withPhase:v];
    //NSLog(@"control signal %f", v);
}

- (void) addSampleWithTime: (CMTime) t
                     value: (float) v
               andStreamID: (int) ID
{
    switch (ID) {
        case STREAM_PPG:
            [self.HRDelegate newPPGSampleReady:v];
            break;
//        case STREAM_TACHOGRAM:
//            [HRperiods addObject:[NSNumber numberWithFloat:v]];
//            break;
//        case STREAM_DETECTED_QUALITY:
//            [breathQuality addObject:[NSNumber numberWithFloat:v]];
        default:
            break;
    }
}

- (NSArray *) getPPGsamples
{
    if (savePPGSamples)
        return self.PPGCollector.samples;
    else
        return @[];
}

- (NSArray *) getHrPeriods
{
    return _hrDetector.HRperiods;
}
- (NSArray *) getBreathingQuality
{
    return _brDetector.breathQuality;
}

- (void)startHeartEngineSavingRawCameraSamples:(BOOL)saveRawPPG forDuration:(int)seconds
{
    
    savePPGSamples = saveRawPPG;
    // during initialisation
    
    // Get NSTimeInterval of uptime i.e. the delta: now - bootTime
    NSDate *startTime = [NSDate date];
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    // Now since dev start
    self.devStartTime = [startTime dateByAddingTimeInterval:-uptime];
    
    // NO ARC?!?!?!
    //    [self.devStartTime retain];
    
    // build the pipeline:
    // camera is both a stage of the pipeline and the HRDetector, this has to change
    // camera and accelerometer go into tee
    // tee goes to logger and brDetector
    int framerate = 30;
    self.camera = [[cameraController alloc] initWithBestSampleFrequency];
    framerate = self.camera.framerate * 2.0;
    self.samplerate = self.camera.framerate;
    // the longest section we collect is 120 seconds
    if (saveRawPPG)
        self.PPGCollector = [[Collector alloc] initWithSize:self.camera.framerate*seconds];
//    framerate = self.camera.framerate * 2 < 120 ? self.camera.framerate * 2 : 120;
    //camera.hrdelegate = _HRDelegate;
    NSLog(@"camera framerate set to = %d", framerate);
    //logger = [[PDDataLogger alloc] init];
    
    int sumslopeSize = (int) (framerate * 0.128 + 0.5);
    int wabpSize = framerate * 2;
    
    
    self.hrDetector = [[HRDetector alloc] initWithPeriod:10.0];
    self.converter = [[PipelineStageToStream alloc] init];
    
    self.hrDetector.delegate = self.HRDelegate;
    
    
    
    // HR
    int lopSize = framerate/15;
    BufferedFunctions *lop = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:lopSize];
    BufferedFunctions *invertCamera = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *sumslope = [[BufferedFunctions alloc] initWithType:BUFFERED_SUM_SLOPE_FUNCTION andSize:sumslopeSize]; // 8 ~ 60*0.128
    BufferedFunctions *wabp = [[BufferedFunctions alloc] initWithType:BUFFERED_WABP andSize:wabpSize];
    
    MakeUniformTime *uniformPPG = [[MakeUniformTime alloc] initWithSamplerate:framerate]; // ensure the HR engine has uniform data
    MakeUniformTime *uniformPPGForDisplay = [[MakeUniformTime alloc] initWithSamplerate:30]; // display at 30 hz

    StreamTee *teePPG = [[StreamTee alloc] init];

    
    self.camera.hrDetector = self.hrDetector;
    self.camera.streamdelegate = self.converter;
    
    if (saveRawPPG)
    {
        self.converter.cameraDelegate = [[StreamTee alloc] initWithDelegates:@[lop, self.PPGCollector]];
    } else
    {
        self.converter.cameraDelegate = lop;
    }
    lop.delegate = teePPG;
    teePPG.delegates = @[uniformPPG
                         , uniformPPGForDisplay
                         //                         , [[StreamLogger alloc] initWithName:@"rawcamera"]
                         ];

    uniformPPGForDisplay.delegate = self;
    uniformPPG.delegate = invertCamera;
    invertCamera.delegate = sumslope;
    //    invertCamera.delegate = [[StreamTee alloc] initWithDelegates: @[
    //                                                                    sumslope
    ////                                                                    , [[StreamLogger alloc] initWithName:@"cameraForSSF"]
    //                                                                    ]];
    
    sumslope.delegate = wabp;
    //    sumslope.delegate = [[StreamTee alloc] initWithDelegates: @[
    //                                                                wabp
    ////                                                                , [[StreamLogger alloc] initWithName:@"SSF"]
    //                                                                ]];
    
    
    
    //    camera.pulseStreamDelegate = uniformTachogram;
    wabp.delegate = [[StreamTee alloc] initWithDelegates:@[self.hrDetector]];
    
    
    // start the pipeline
    //    [logger startLogging];
    [_camera resetData];
    [_camera didBecomeActive];
}


-(void)testHeartEngineWithDummyCamera:(SignalGenerator *)fakeCamera withSampleRate:(float)sampleRate withLogs:(BOOL)logs
{
    savePPGSamples = YES;
    // during initialisation
    
    // Get NSTimeInterval of uptime i.e. the delta: now - bootTime
    NSDate *startTime = [NSDate date];
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    // Now since dev start
    self.devStartTime = [startTime dateByAddingTimeInterval:-uptime];
    
    // NO ARC?!?!?!
    //    [self.devStartTime retain];
    
    // build the pipeline:
    // camera is both a stage of the pipeline and the HRDetector, this has to change
    // camera and accelerometer go into tee
    // tee goes to logger and brDetector
    int framerate = sampleRate * 2;
    //camera.hrdelegate = _HRDelegate;
//    NSLog(@"camera framerate set to = %d", framerate);
    //logger = [[PDDataLogger alloc] init];
    
    int sumslopeSize = (int) (framerate * 0.128 + 0.5); // SSF window is 0.128s
    int wabpSize = framerate * 2; // 2s
    
    
    self.hrDetector = [[HRDetector alloc] initWithPeriod:10.0];
    self.converter = [[PipelineStageToStream alloc] init];
    
    self.hrDetector.delegate = self.HRDelegate;
    
    
    
    // HR
    int lopSize = framerate > 60 ? framerate/60 : 1;
    BufferedFunctions *lop = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:lopSize];
    BufferedFunctions *invertCamera = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *sumslope = [[BufferedFunctions alloc] initWithType:BUFFERED_SUM_SLOPE_FUNCTION andSize:sumslopeSize]; // 8 ~ 60*0.128
    BufferedFunctions *wabp = [[BufferedFunctions alloc] initWithType:BUFFERED_WABP andSize:wabpSize];
    
    MakeUniformTime *uniformPPG = [[MakeUniformTime alloc] initWithSamplerate:framerate]; // ensure the HR engine has uniform data
    MakeUniformTime *uniformPPGForDisplay = [[MakeUniformTime alloc] initWithSamplerate:30]; // display at 30 hz
    
    StreamTee *teePPG = [[StreamTee alloc] init];
    
    
    
    fakeCamera.delegate  = lop;
    lop.delegate = teePPG;

    if (logs)
    {
        teePPG.delegates = @[uniformPPG
                             ,uniformPPGForDisplay
                             , [[StreamLogger alloc] initWithName:@"fakeCamera"]
                             ];
        
    } else
    {
        teePPG.delegates = @[uniformPPG
                             ,uniformPPGForDisplay
                             ];
        
    }
    uniformPPGForDisplay.delegate = self;
    uniformPPG.delegate = invertCamera;
    if (logs)
    {
        invertCamera.delegate = [[StreamTee alloc] initWithDelegates: @[
                                                                        sumslope
                                                                        , [[StreamLogger alloc] initWithName:@"cameraForSSF"]
                                                                        ]];
        sumslope.delegate = [[StreamTee alloc] initWithDelegates: @[
                                                                    wabp
                                                                    , [[StreamLogger alloc] initWithName:@"SSF"]
                                                                    ]];
        wabp.delegate = [[StreamTee alloc] initWithDelegates:@[self.hrDetector
                                                               , [[StreamLogger alloc] initWithName:@"WABP"]
                                                               ]];
        
    } else
    {
        invertCamera.delegate = [[StreamTee alloc] initWithDelegates: @[
                                                                        sumslope
                                                                        ]];
        sumslope.delegate = [[StreamTee alloc] initWithDelegates: @[
                                                                    wabp
                                                                    ]];
        wabp.delegate = [[StreamTee alloc] initWithDelegates:@[self.hrDetector
                                                               ]];
        
    }
    
}

- (void)testBreathEngineWithDummyCamera:(SignalGenerator *)fakeCamera
                         withSampleRate:(float)sampleRate
                withControlSignalPeriod:(float)period
                 withDummyControlSignal:(SignalGenerator *)fakeControlSignal
                 withDummyAccelerometer:(SignalGenerator *)fakeAccelerometer
                                andLogs:(BOOL)logs
{
    savePPGSamples = NO;
    // during initialisation
    
    // Get NSTimeInterval of uptime i.e. the delta: now - bootTime
    NSDate *startTime = [NSDate date];
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    // Now since dev start
    self.devStartTime = [startTime dateByAddingTimeInterval:-uptime];
    
    // NO ARC?!?!?!
    //    [self.devStartTime retain];
    
    // build the pipeline:
    // camera is both a stage of the pipeline and the HRDetector, this has to change
    // camera and accelerometer go into tee
    // tee goes to logger and brDetector
    int framerate = sampleRate * 2;

    //    NSLog(@"camera framerate set to = %d", framerate);
    //logger = [[PDDataLogger alloc] init];
    BOOL accelerometerPresent = fakeAccelerometer != nil;
    
    self.brDetector = [[BRDetector alloc] initWithCamera:YES andAccelerometer:accelerometerPresent];
    self.brDetector.delegate = _BRDelegate;
    
    int samplesForLPFilterPPG = 30;
    int delayLPFilterPPG = samplesForLPFilterPPG/2;
    int samplesForDetrendPPG = 30;
    int samplesForNormPPG = 60;
    
    
    int samplesForLPFilterTachgoram = 30;
    int samplesForDetrendTachgoram = 30;
    int samplesForNormTachgoram = 60;
    
    int samplesForLPFilterACC = 30;
    int samplesForDetrendACC = 30;
    int samplesForNormACC = 60;
    int samplePeriod = period * 10;
    int samplesForCorrelation = powf(2, ceilf(log(samplePeriod)/log(2.0)));
    int downsamplingFactor = framerate/10; // output is 10Hz
    int sumslopeSize = (int) (framerate * 0.128 + 0.5);
    int wabpSize = framerate * 2;

    // how many samples of the control signal we have to discard to ensure it's in synch with tachogram
    int samplesForDiscardHeadTachogram = 0.128 * 10 + 2*10 + samplesForDetrendTachgoram + samplesForNormTachgoram;
    
    self.hrDetector = [[HRDetector alloc] initWithPeriod:period];
    self.converter = [[PipelineStageToStream alloc] init];
    
    self.hrDetector.delegate = self.HRDelegate;
    
    // ------------------ breathing detector ------------------
    // PPG
    Downsampler *downsamplerPPG = [[Downsampler alloc] initWithDownsamplingFactor:downsamplingFactor];
    BufferedFunctions *avgmidPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:samplesForLPFilterPPG];
    BufferedFunctions *detrendendPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendPPG];
    BufferedFunctions *normalizerPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormPPG];
    BufferedFunctions *inverterPPG = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *delayControl = [[BufferedFunctions alloc] initWithType:BUFFERED_DELAY andSize:delayLPFilterPPG];
    StreamTee *teeCleanPPG = [[StreamTee alloc] init];
    StreamTee *teeControlSignal = [[StreamTee alloc] init];
    StreamTee *teeControlSignalDelayed = [[StreamTee alloc] init];
    StreamTee *teePPG = [[StreamTee alloc] init];
    CrossCorrelation *correlationPPG = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationPPG.producedCorrelationStreamID = STREAM_PPG_QUALITY;
    correlationPPG.producedPhaseStreamID = STREAM_PPG_PHASE;
    
    // Tachogram
    BufferedFunctions *normalizerTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormTachgoram];
    BufferedFunctions *inverterTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    MakeUniformTime *uniformTachogram = [[MakeUniformTime alloc] initWithSamplerate:10.0]; // breathing engine fixed at 10Hz
    MakeUniformTime *uniformPPG = [[MakeUniformTime alloc] initWithSamplerate:framerate]; // ensure the HR engine has uniform data
    MakeUniformTime *uniformPPGForDisplay = [[MakeUniformTime alloc] initWithSamplerate:30]; // display at 30 hz
    StreamTee *teeTachogram = [[StreamTee alloc] init];
    BufferedFunctions *detrendendTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendTachgoram];
    CrossCorrelation *correlationTachogram = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationTachogram.producedCorrelationStreamID = STREAM_TACHOGRAM_QUALITY;
    correlationTachogram.producedPhaseStreamID = STREAM_TACHOGRAM_PHASE;
    DiscardHead *discardHeadTachogram = [[DiscardHead alloc] initWithSize:samplesForDiscardHeadTachogram];
    
    // Accelerometer
    CrossCorrelation *correlationACC = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationACC.producedCorrelationStreamID = STREAM_ACCELEROMETER_QUALITY;
    correlationACC.producedPhaseStreamID = STREAM_ACCELEROMETER_PHASE;
    BufferedFunctions *avgmidACC = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:samplesForLPFilterACC];
    BufferedFunctions *detrendendACC = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendACC];
    BufferedFunctions *normalizerACC = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormACC];
    
    // HR
    int lopSize = framerate > 60 ? framerate/60 : 1;
    BufferedFunctions *lop = [[BufferedFunctions alloc] initWithType:BUFFERED_AVERAGE_MID andSize:lopSize];
    BufferedFunctions *invertCamera = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    BufferedFunctions *sumslope = [[BufferedFunctions alloc] initWithType:BUFFERED_SUM_SLOPE_FUNCTION andSize:sumslopeSize]; // 8 ~ 60*0.128
    BufferedFunctions *wabp = [[BufferedFunctions alloc] initWithType:BUFFERED_WABP andSize:wabpSize];
    
    
    
//    self.camera.hrDetector = self.hrDetector;
//    self.camera.streamdelegate = self.converter;
//    self.converter.controlSignalDelegate = teeControlSignal;
    fakeControlSignal.delegate = teeControlSignal;
    
    teeControlSignal.delegates = @[discardHeadTachogram];
    discardHeadTachogram.delegate = correlationTachogram;

//    teeControlSignal.delegates = @[delayControl , correlationTachogram ];
//    delayControl.delegate = teeControlSignalDelayed;
//    teeControlSignalDelayed.delegates = @[correlationPPG, correlationACC /*, [[StreamLogger alloc] initWithName:@"control" ] */ ];

    
//    self.converter.cameraDelegate = teePPG;
    fakeCamera.delegate = lop;
    lop.delegate = teePPG;
    if (logs)
    {
        teePPG.delegates = @[
                             downsamplerPPG
                             , uniformPPG
                             , uniformPPGForDisplay
                             , [[StreamLogger alloc] initWithName:@"rawcamera"]
                             ];
        
    } else
    {
        teePPG.delegates = @[
                             downsamplerPPG
                             , uniformPPG
                             , uniformPPGForDisplay
                             //                         , [[StreamLogger alloc] initWithName:@"rawcamera"]
                             ];
        
    }
    uniformPPGForDisplay.delegate = self;
    uniformPPG.delegate = invertCamera;
    downsamplerPPG.delegate = avgmidPPG;
    avgmidPPG.delegate = detrendendPPG;
    detrendendPPG.delegate = normalizerPPG;
    normalizerPPG.delegate = inverterPPG;
    inverterPPG.delegate = teeCleanPPG;
    teeCleanPPG.delegates = @[
                              correlationPPG
                              , self.brDetector ,
                              /*[[StreamLogger alloc] initWithName:@"PPG" ] */
                              ];
    invertCamera.delegate = sumslope;
    //    invertCamera.delegate = [[StreamTee alloc] initWithDelegates: @[
    //                                                                    sumslope
    ////                                                                    , [[StreamLogger alloc] initWithName:@"cameraForSSF"]
    //                                                                    ]];
    sumslope.delegate = wabp;
    //    sumslope.delegate = [[StreamTee alloc] initWithDelegates: @[
    //                                                                wabp
    ////                                                                , [[StreamLogger alloc] initWithName:@"SSF"]
    //                                                                ]];
    
    
//    self.accelerometer.delegate = self.converter;
//    self.converter.accelerometerDelegate = avgmidACC;
    fakeAccelerometer.delegate = avgmidACC;
    avgmidACC.delegate = detrendendACC;
    detrendendACC.delegate = normalizerACC;
    if (logs)
    {
        normalizerACC.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                        correlationACC
                                                                        , [[StreamLogger alloc] initWithName:@"Accelerometer" ]
                                                                        ]];
        
    } else
    {
        normalizerACC.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                        correlationACC
                                                                        //                                                                    , [[StreamLogger alloc] initWithName:@"Accelerometer" ]
                                                                        ]];
    }
    
    //    camera.pulseStreamDelegate = uniformTachogram;
    if (logs)
    {
        wabp.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                               uniformTachogram
                                                               , self.hrDetector
                                                               , [[StreamLogger alloc] initWithName:@"wabp"]
                                                               ]];
        
    } else
    {
        wabp.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                               uniformTachogram
                                                               , self.hrDetector
                                                               //                                                           , [[StreamLogger alloc] initWithName:@"wabp"]
                                                               ]];
    }
    
    //    uniformTachogram.delegate = detrendendTachogram;
    if (logs)
    {
        uniformTachogram.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                           detrendendTachogram
                                                                           , [[StreamLogger alloc] initWithName:@"uniformTachogram"]
                                                                           ]];
        
    } else
    {
        uniformTachogram.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                           detrendendTachogram
                                                                           //                                                                       , [[StreamLogger alloc] initWithName:@"uniformTachogram"]
                                                                           ]];
        
    }
    detrendendTachogram.delegate = normalizerTachogram;
    normalizerTachogram.delegate = inverterTachogram;
    inverterTachogram.delegate = teeTachogram;
    //    camera.pulseStreamDelegate = teeTachogram;
    teeTachogram.delegates = @[
                               correlationTachogram
                               //                               , [[StreamLogger alloc] initWithName:@"tachogramForCorrelation" ]
                               ];
    
    correlationTachogram.delegateCorrelation = [[StreamTee alloc] initWithDelegates: @[
                                                                                       self.brDetector
                                                                                       //                                                                                       , [[StreamLogger alloc] initWithName:@"tachogramCorr"]
                                                                                       ]];
    correlationTachogram.delegatePhase = self.brDetector;
    correlationPPG.delegateCorrelation =  [[StreamTee alloc] initWithDelegates: @[
                                                                                  self.brDetector
                                                                                  //                                                                                  , [[StreamLogger alloc] initWithName:@"PPGCorrelation" ]
                                                                                  ]];
    correlationPPG.delegatePhase = self.brDetector;
    correlationACC.delegateCorrelation = [[StreamTee alloc] initWithDelegates: @[
                                                                                 self.brDetector
                                                                                 //                                                                                 , [[StreamLogger alloc] initWithName:@"AccCorrelation" ]
                                                                                 ]];
    correlationACC.delegatePhase = self.brDetector;
    
    // start the pipeline
    //    [logger startLogging];
//    [_camera resetData];
//    [_camera didBecomeActive];
//    [_accelerometer startAccelerometer];
}

- (void) resetPPGCollector
{
    [self.PPGCollector resetCollector];
}


#pragma mark methods for external HR detectors

- (void) startBreathEngineWithExternalHRDetectorandControlSignalPeriod: (float) period
{
    savePPGSamples = NO;
    BOOL logs = NO;
    // during initialisation
    NSDate *startTime = [NSDate date];
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    // Now since dev start
    self.devStartTime = [startTime dateByAddingTimeInterval:-uptime];

    
    self.brDetector = [[BRDetector alloc] initWithCamera:YES andAccelerometer:NO];
    self.brDetector.delegate = _BRDelegate;
    
//    int samplesForLPFilterPPG = 30;
//    int delayLPFilterPPG = samplesForLPFilterPPG/2;
//    int samplesForDetrendPPG = 30;
//    int samplesForNormPPG = 60;
    
    int samplesForLPFilterTachgoram = 30;
    int samplesForDetrendTachgoram = 30;
    int samplesForNormTachgoram = 60;
    
    int samplePeriod = period * 10;
    int samplesForCorrelation = powf(2, ceilf(log(samplePeriod)/log(2.0)));
    
    // how many samples of the control signal we have to discard to ensure it's in synch with tachogram
    int samplesForDiscardHeadTachogram = 0.128 * 10 + 2*10 + samplesForDetrendTachgoram + samplesForNormTachgoram;
    
    self.hrDetector = [[HRDetector alloc] initWithPeriod:period];
    self.converter = [[PipelineStageToStream alloc] init];
    
    self.hrDetector.delegate = self.HRDelegate;
    
    // ------------------ breathing detector ------------------
    // PPG

    StreamTee *teeControlSignal = [[StreamTee alloc] init];
    StreamTee *teeControlSignalDelayed = [[StreamTee alloc] init];
    
    // Tachogram
    BufferedFunctions *normalizerTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_NORMALISE andSize:samplesForNormTachgoram];
    BufferedFunctions *inverterTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_INVERT andSize:1];
    self.uniformTachogramExternalDetector = [[MakeUniformTime alloc] initWithSamplerate:10.0]; // breathing engine fixed at 10Hz
    StreamTee *teeTachogram = [[StreamTee alloc] init];
    BufferedFunctions *detrendendTachogram = [[BufferedFunctions alloc] initWithType:BUFFERED_DETREND andSize:samplesForDetrendTachgoram];
    CrossCorrelation *correlationTachogram = [[CrossCorrelation alloc] initWithSize:samplesForCorrelation];
    correlationTachogram.producedCorrelationStreamID = STREAM_TACHOGRAM_QUALITY;
    correlationTachogram.producedPhaseStreamID = STREAM_TACHOGRAM_PHASE;
    DiscardHead *discardHeadTachogram = [[DiscardHead alloc] initWithSize:samplesForDiscardHeadTachogram];
    
    self.converter.controlSignalDelegate = teeControlSignal;
    teeControlSignal.delegates = @[discardHeadTachogram];
    discardHeadTachogram.delegate = correlationTachogram;
    
    
    //    uniformTachogram.delegate = detrendendTachogram;
    if (logs)
    {
        self.uniformTachogramExternalDetector.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                           detrendendTachogram
                                                                           , [[StreamLogger alloc] initWithName:@"uniformTachogram"]
                                                                           ]];
        
    } else
    {
        self.uniformTachogramExternalDetector.delegate = [[StreamTee alloc] initWithDelegates:@[
                                                                           detrendendTachogram
                                                                           //                                                                       , [[StreamLogger alloc] initWithName:@"uniformTachogram"]
                                                                           ]];
        
    }
    detrendendTachogram.delegate = normalizerTachogram;
    normalizerTachogram.delegate = inverterTachogram;
    inverterTachogram.delegate = teeTachogram;
    //    camera.pulseStreamDelegate = teeTachogram;
    teeTachogram.delegates = @[
                               correlationTachogram
                               //                               , [[StreamLogger alloc] initWithName:@"tachogramForCorrelation" ]
                               ];
    
    correlationTachogram.delegateCorrelation = [[StreamTee alloc] initWithDelegates: @[
                                                                                       self.brDetector
                                                                                       //                                                                                       , [[StreamLogger alloc] initWithName:@"tachogramCorr"]
                                                                                       ]];
    correlationTachogram.delegatePhase = self.brDetector;
    
    
}

- (void) addRRintervalWithTimestamp: (NSDate *) date
                      andRRInterval: (float) interval
{
    // we are just trusting the date passed as parameter
    // we should be
    NSTimeInterval t = [date timeIntervalSinceDate:self.devStartTime];
    CMTime time = CMTimeMake((int64_t)(t * 1.0e5), 1e5);
    [self.uniformTachogramExternalDetector addSampleWithTime:time value:interval andStreamID:STREAM_TACHOGRAM];
}

+ (BOOL)hasDualCamera
{
    return [cameraController hasDualCamera];
}

@end
