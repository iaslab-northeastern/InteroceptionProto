#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "BREventsDelegate.h"
#import "HeartDetectorEngine.h"
#import "HREventsDelegate.h"
#import "HRVFeatureExtractor.h"
#import "StreamAnalyzer.h"
#import "AccelerometerHelper.h"
#import "cameraController.h"
#import "Collector.h"
#import "BRDetector.h"
#import "HRDetector.h"
#import "HRMCameraDataDistiller.h"
#import "HRMSampleStreamAnalyzer.h"
#import "PDDataLogger.h"
#import "PDDataTee.h"
#import "PipelineStageToStream.h"
#import "BufferedFunctions.h"
#import "CrossCorrelation.h"
#import "DiscardHead.h"
#import "Downsampler.h"
#import "MakeUniformTime.h"
#import "SerieAnalyzer.h"
#import "SignalGenerator.h"
#import "StreamLogger.h"
#import "StreamTee.h"

FOUNDATION_EXPORT double HeartDetectorEngineVersionNumber;
FOUNDATION_EXPORT const unsigned char HeartDetectorEngineVersionString[];

