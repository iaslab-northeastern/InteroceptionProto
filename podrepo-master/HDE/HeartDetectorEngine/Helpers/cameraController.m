//
//  cameraController.m
//  BioBeats
//
//  Created by Davide Morelli on 8/17/12.
//  Copyright (c) 2012 BioBeats. All rights reserved.
//

#import "cameraController.h"
#define CAMERA_SERIAL_QUEUE "cameraSerialQueue"

#import "PDDataTee.h"
#import <sys/utsname.h>

@interface cameraController()
{
    
}

- (int) findFramerate;

@end

@implementation cameraController{
    dispatch_queue_t cameraQueue;
}
@synthesize hrdelegate;
@synthesize streamdelegate = _streamdelegate;
@synthesize pulseStreamDelegate;
@synthesize fingerPresent;
@synthesize hrDetector;
@synthesize framerate;

- (id) initWithBestSampleFrequency
{
    self = [super init];
    cameraQueue = dispatch_queue_create(CAMERA_SERIAL_QUEUE, DISPATCH_QUEUE_SERIAL);
    serialqueue = dispatch_queue_create("biobeats.com.serial.heartrate", DISPATCH_QUEUE_SERIAL);
    samplesHeart = [[NSMutableArray alloc] init];
    samplesBPM = [[NSMutableArray alloc] init];
    samplesDiff = [[NSMutableArray alloc] init];
    periods = [[NSMutableArray alloc] init];
    SAMPLFREQ = [self findFramerate];
    if (SAMPLFREQ > 120)
        SAMPLFREQ = 120;
    BUFFERLENGTH = SAMPLFREQ <= 30 ? 64 :
                    SAMPLFREQ <= 60 ? 128 :
                    SAMPLFREQ <= 120 ? 256 : 512;
    BUFFERLENGTHOVER2 = SAMPLFREQ / 2;
    LOG2BUFFERLENGTH = (int) log2(BUFFERLENGTH);
    LOG2BUFFERLENGTHOVER2 = (int) log2(BUFFERLENGTHOVER2);
    MINBPM = 30;
    MAXBPM = 240;
    MINQUALITY = 0.3;
    FAST_PERIODS = SAMPLFREQ <= 30 ? 5 :
                    SAMPLFREQ <= 60 ? 11 :
                    SAMPLFREQ <= 120 ? 21 : 41;
    SLOW_PERIODS = SAMPLFREQ <= 30 ? 17 :
                    SAMPLFREQ <= 60 ? 35 :
                    SAMPLFREQ <= 120 ? 71 : 131;
    lastPeriod = 0;
    
    self.framerate = SAMPLFREQ;
    return self;
}

- (void)dealloc
{
    [self freeArrays];
//    dispatch_release(serialqueue);
}

- (int) getMINQUALITY
{
    return MINQUALITY;
}

- (int) getSAMPLFREQ
{
    return SAMPLFREQ;
}

- (int) getBUFFERLENGTH
{
    return BUFFERLENGTH;
}

- (NSArray *) getDiffBuffer
{
    return samplesDiff;
}

- (NSArray *) getBPMBuffer
{
    return samplesBPM;
}

- (NSArray *) getHeartBuffer
{
    return samplesHeart;
}

- (NSArray *) getPeriods
{
    return periods;
}

- (float *) getDiffFloats
{
    return diff;
}

- (int) getCurrentArrayIndex
{
    return currentArrayIndex;
}

- (float) getCurrDiff
{
    return currDiff;
}

-(bool) getDataReady
{
    return dataReady;
}

-(float) getQuality
{
    return quality;
}

- (BOOL) getFingerPresent
{
    return fingerPresent;
}

- (void) freeArrays
{
    if (!arraysAllocated)
        return;
//    free(obtainedReal);
//    free(originalReal);
//    free(A.realp);
//    free(A.imagp);
//    free(hanningWindow);
//    free(noiseRemoverWindow);
//    free(binMagnitude);
//    vDSP_destroy_fftsetup(setupReal);
    free(fastAvg);
    free(slowAvg);
    free(rateHistory);
    free(samples);
    free(diff);
    free(wAvgSamples);
    free(hrv);
    free(pulseHistory);
    //dispatch_release(serialqueue);
    arraysAllocated = NO;
}

- (void) resetData
{
    [self freeArrays];
    [samplesHeart removeAllObjects];
    [samplesBPM removeAllObjects];
    [samplesDiff removeAllObjects];
    [periods removeAllObjects];
    
    currentArrayIndex=0;
    prevSampleTime = -1;
    
    minDiff = -99.0;
    maxDiff = 99.0;
    
    slowAvg = (float *) malloc(BUFFERLENGTH * sizeof(float));
    fastAvg = (float *) malloc(BUFFERLENGTH * sizeof(float));
    pulseHistory = (bool *) malloc(BUFFERLENGTH * sizeof(bool));
    diff = (float *) malloc(BUFFERLENGTH * sizeof(float));
    samples = (float *) malloc(BUFFERLENGTH * sizeof(float));
    wAvgSamples = (float *) malloc(BUFFERLENGTH * sizeof(float));
    hrv = (float *) malloc(BUFFERLENGTH * sizeof(float));
    float zero = 0.0f;
    currentHrvIndex = 0;
    
    vDSP_vfill(&zero, hrv, 1, BUFFERLENGTH);
    vDSP_vfill(&zero, slowAvg, 1, BUFFERLENGTH);
    vDSP_vfill(&zero, fastAvg, 1, BUFFERLENGTH);
    vDSP_vfill(&zero, diff, 1, BUFFERLENGTH);
    vDSP_vfill(&zero, samples, 1, BUFFERLENGTH);
    vDSP_vfill(&zero, wAvgSamples, 1, BUFFERLENGTH);
    
//    A.realp = (float *) malloc(BUFFERLENGTHOVER2 * sizeof(float));
//    A.imagp = (float *) malloc(BUFFERLENGTHOVER2 * sizeof(float));
//    originalReal = (float *) malloc(BUFFERLENGTH * sizeof(float));
//    obtainedReal = (float *) malloc(BUFFERLENGTH * sizeof(float));
//    binMagnitude = (float *) malloc(BUFFERLENGTHOVER2 * sizeof(float));
//    noiseRemoverWindow = (float *) malloc(BUFFERLENGTHOVER2 * sizeof(float));
    rateHistory = (float *) malloc(64 * sizeof(float));
//    for (int i=0; i<BUFFERLENGTHOVER2/4; i++) {
//        noiseRemoverWindow[i]=1.0f;
//    }
//    for (int i=BUFFERLENGTHOVER2/4; i<BUFFERLENGTHOVER2; i++) {
//        noiseRemoverWindow[i]=0.0f;
//    }
    
    /* Set up the required memory for the FFT routines and check  its
     * availability. */
//    setupReal = vDSP_create_fftsetup(LOG2BUFFERLENGTH, FFT_RADIX2);
//    if (setupReal == NULL) {
//        NSLog(@"FFT_Setup failed to allocate enough memory  for the real FFT.");
//        // TODO
//    }
    
    arraysAllocated = YES;
    
}

- (void)addControlSignalForTime:(CMTime)t withPhase:(float)p
{
    [_streamdelegate addControlSignalForTime:t withPhase:p];
}

- (void) addAccelerationForTime:(CMTime) t
                          withX:(float) x
                          withY:(float) y
                          withZ:(float) z
{
    [_streamdelegate addAccelerationForTime:t withX:x withY:y withZ:z];
}

- (void)lockCamera
{
    dispatch_async(cameraQueue, ^{
        [device lockForConfiguration:nil];
        if([device isExposureModeSupported:AVCaptureExposureModeLocked]){
            device.exposurePointOfInterest = CGPointMake(0.5, 0.5);
            device.exposureMode = AVCaptureExposureModeLocked;
        }
        [device unlockForConfiguration];
        NSLog(@"camera locked");
        cameraLocked = YES;
    });
}

- (void) unlockCamera
{
    dispatch_async(cameraQueue, ^{
        [device lockForConfiguration:nil];
        if([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            device.exposurePointOfInterest = CGPointMake(0.5, 0.5);
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        [device unlockForConfiguration];
        NSLog(@"camera unlocked");
        cameraLocked = NO;
    });
}

- (void) addSampleForTime:(CMTime) t
                  withRed:(float) r
                withGreen:(float) g
                 withBlue:(float) b
{
    dispatch_async(cameraQueue, ^{
        r_avg = r;
        g_avg = g;
        b_avg = b;
        rgb_avg = (r + g + b) / 3;
        
        float rgb = (r+g+b)/3.0;
        //    NSLog(@"r %f g %f b %f rgb %f", r, g, b, rgb);
        BOOL outerThreshold = NO;
        BOOL innerThreshold = NO;
        if (r > 100 && g < 60 && b < 100 && rgb > 20 && rgb < 200 )
            outerThreshold = YES;
        if (r > 110 && g < 60 && b < 100 && rgb > 20 && rgb < 200 )
            innerThreshold = YES;
        
        if (!outerThreshold) {
            if (self.fingerPresent)
            {
                self.fingerPresent = NO;
                [hrDetector fingerPresent:NO];
                [hrdelegate fingerPresentChanged:NO];
                // target color lost, unlock exposure
                [self unlockCamera];
            }
            // no else branch: finger was already set as not present
        } else
        {
            if (innerThreshold)
            {
                if (!self.fingerPresent)
                {
                    // finger now present, lock camera
                    self.fingerPresent = YES;
                    [hrDetector fingerPresent:YES];
                    [hrdelegate fingerPresentChanged:YES];
                    [self lockCamera];
                }
            } else
            {
                // we are between the inner and outer threshold
                // if finger nor present keep going until we reach the inner threshold
                // if finger present keep going until we exit the outer threshold
                // in both cases do nothing
            }
            
        }

    });
//
//    double CurrentTime = CACurrentMediaTime();
//    dispatch_async(serialqueue,
//                   ^{
////                       if (r_avg > 120 && g_avg < 120 && b_avg < 80 && rgb_avg > 20 && rgb_avg < 160 )
//                           //if (1)
//                       if (cameraLocked)
//                       {
//                           float target = (rgb_avg-prev_sample)*(rgb_avg-prev_sample);
//                           prev_sample = rgb_avg;
//                           
//#ifdef LOGPULSEOXIMETER
//                           NSLog(@";%f;%f;",target, lastPeriod);
//#endif
//
//                           
//                           if (prevSampleTime > 0 && CurrentTime - prevSampleTime > 1.0/((float)SAMPLFREQ))
//                           {
//                               // worths interpolating..
//                               int prevIndex = (currentArrayIndex-1+BUFFERLENGTH)%BUFFERLENGTH;
//                               double period = 1.0/((float)SAMPLFREQ);
//                               int numberOfSamples = (CurrentTime - prevSampleTime)/period;
//                               float lastVal = samples[prevIndex];
//                               float incr = (target - lastVal)/((float)numberOfSamples);
//                               for (int i=0; i<numberOfSamples; i++) {
//                                   float thisVal = lastVal + incr*((float)i);
//                                   samples[currentArrayIndex] = thisVal;
//                                   [samplesHeart addObject:[NSNumber numberWithFloat:thisVal]];
//                                   wAvgSamples[currentArrayIndex] = (thisVal + wAvgSamples[(currentArrayIndex + BUFFERLENGTH - 1) % BUFFERLENGTH])/2;
//                                   // fast avg
//                                   float fast = 0.0;
//                                   for (int i=0; i<FAST_PERIODS; i++) {
//                                       fast += samples[(currentArrayIndex - i + BUFFERLENGTH)%BUFFERLENGTH];
//                                   }
//                                   fast = fast / ((float) FAST_PERIODS);
//                                   fastAvg[currentArrayIndex] = fast;
//                                   // slow avg
//                                   float slow = 0.0;
//                                   for (int i=0; i<SLOW_PERIODS; i++) {
//                                       slow += samples[(currentArrayIndex - i + BUFFERLENGTH)%BUFFERLENGTH];
//                                   }
//                                   slow = slow / ((float) SLOW_PERIODS);
//                                   slowAvg[currentArrayIndex] = slow;
//                                   diff[currentArrayIndex] = fast - slow;
//                                   [samplesDiff addObject:[NSNumber numberWithFloat:diff[currentArrayIndex]]];
//                                   pulseHistory[currentArrayIndex] = fast < slow;
//                                   currentArrayIndex++;
//                                   if (currentArrayIndex >= BUFFERLENGTH)
//                                   {
//                                       dataReady = true;
//                                       currentArrayIndex = 0;
//                                   }
//                               }
//                           } else
//                           {
//                               // no need to interpolate...
//                               samples[currentArrayIndex] = target;
//                               [samplesHeart addObject:[NSNumber numberWithFloat:samples[currentArrayIndex]]];
//                               wAvgSamples[currentArrayIndex] = (samples[currentArrayIndex] + wAvgSamples[(currentArrayIndex + BUFFERLENGTH - 1) % BUFFERLENGTH])/2;
//                               // fast avg
//                               float fast = 0.0;
//                               for (int i=0; i<FAST_PERIODS; i++) {
//                                   fast += samples[(currentArrayIndex - i + BUFFERLENGTH)%BUFFERLENGTH];
//                               }
//                               fast = fast / ((float) FAST_PERIODS);
//                               fastAvg[currentArrayIndex] = fast;
//                               // slow avg
//                               float slow = 0.0;
//                               for (int i=0; i<SLOW_PERIODS; i++) {
//                                   slow += samples[(currentArrayIndex - i + BUFFERLENGTH)%BUFFERLENGTH];
//                               }
//                               slow = slow / ((float) SLOW_PERIODS);
//                               slowAvg[currentArrayIndex] = slow;
//                               diff[currentArrayIndex] = fast - slow;
//                               [samplesDiff addObject:[NSNumber numberWithFloat:diff[currentArrayIndex]]];
//                               pulseHistory[currentArrayIndex] = fast < slow;
//                               currentArrayIndex++;
//                               if (currentArrayIndex >= BUFFERLENGTH)
//                               {
//                                   dataReady = true;
//                                   currentArrayIndex = 0;
//                               }
//                           }
//                           
//                           
//                           vDSP_maxv(diff, 1, &maxDiff, BUFFERLENGTH);
//                           vDSP_minv(diff, 1, &minDiff, BUFFERLENGTH);
//                           float threshold =  minDiff + (maxDiff - minDiff)/3.0;
//                           
//                           currDiff = (diff[currentArrayIndex] - threshold);
////                           currDiff = (diff[currentArrayIndex] - minDiff)/(maxDiff-minDiff);
//                           
//                           prevSampleTime = CurrentTime;
//
//                           int bestIndex = SAMPLFREQ;
//                           int step = 0;
//                           int passed = 1;
//                           while (step == 0 && passed < BUFFERLENGTH) {
//                               if (pulseHistory[(currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH])
//                               {
//                                   step = 1;
//                               }
//                               passed++;
//                           }
//                           while (step == 1 && passed < BUFFERLENGTH) {
//                               if (!pulseHistory[(currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH])
//                               {
//                                   step = 2;
//                                   secondPulse = (currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH;
//                               }
//                               passed++;
//                           }
//                           if (secondPulse == lastSwitchTo2Index)
//                           {
//                               // nothing changed since last time we checked
//                               return;
//                           } else
//                           {
//                               lastSwitchTo2Index = secondPulse;
//                           }
//                           while (step == 2 && passed < BUFFERLENGTH) {
//                               if (pulseHistory[(currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH])
//                               {
//                                   step = 3;
//                               }
//                               passed++;
//                           }
//                           while (step == 3 && passed < BUFFERLENGTH) {
//                               if (!pulseHistory[(currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH])
//                               {
//                                   step = 4;
//                                   firstPulse = (currentArrayIndex-passed+BUFFERLENGTH) % BUFFERLENGTH;
//                               }
//                               passed++;
//                           }
//                           if (step == 4)
//                           {
//                               bestIndex = (secondPulse - firstPulse + BUFFERLENGTH) % BUFFERLENGTH;
//                               quality = 1.0;
//                               //            NSLog(@"first = %d, second=%d", firstPulse, secondPulse);
//                               //NSLog(@"bestIndex = %d", bestIndex);
//                               float p = (((float) bestIndex)/((float) SAMPLFREQ));
//                               if (p<60./MAXBPM || p>60./MINBPM)
//                                   return;
//                               [periods addObject:[NSNumber numberWithFloat:p]];
//                               float bpm = 60./ p;
//                               lastPeriod = ((float) bestIndex)/((float) SAMPLFREQ);
//                               hrv[currentHrvIndex] = bpm;
//                               currentHrvIndex = (currentHrvIndex + 1) % BUFFERLENGTH;
//                               [samplesBPM addObject:[NSNumber numberWithFloat:bpm]];
//                               
//                               float averageBPM = 0.0;
//                               int countBPMItems = 0;
//                               for(int i=[samplesBPM count]-1; i>0 && countBPMItems<15; i--)
//                               {
//                                   averageBPM += [[samplesBPM objectAtIndex:i] floatValue];
//                                   countBPMItems++;
//                               }
//                               averageBPM /= (float) countBPMItems;
//                               // notify a new pulse was detected
//                               //            NSLog(@"sending newpulse with period %f", ((float) bestIndex)/((float) SAMPLFREQ) );
//                               
//#ifdef LOGPERIODS
//                               NSLog(@";%f;",lastPeriod);
//#endif
//
//                               
//                               [pulseStreamDelegate addSampleWithTime:t value:lastPeriod andStreamID:200];
//                               [hrdelegate beatDetectedWithInstantBPM:bpm andAverageBPM:averageBPM];
//                               //[delegate pulseReceived:((float) bestIndex)/((float) SAMPLFREQ)];
//                               
//                               //            [[NSNotificationCenter defaultCenter]
//                               //             postNotificationName:@"NewPulse"
//                               //             object:[NSNumber numberWithFloat:(((float) bestIndex)/((float) SAMPLFREQ))] ];
//                           } else {
//                               quality = 0.0;
//                               //NSLog(@"step was  %d", step);
//                           }
//                           
//                           
//                           
////                           if (!fingerPresent)
////                           {
////                               // finger was not present, now it is
////                               fingerPresent = YES;
////#ifdef DEBUGLOG
////                               NSLog(@"finger detected");
////#endif
////                               [hrdelegate fingerPresentChanged:YES];
////                           }
//                       } else {
////                           if (fingerPresent)
////                           {
////                               // finger was present, now is not
////                               fingerPresent = NO;
////#ifdef DEBUGLOG
////                               NSLog(@"finger not present");
////#endif
////                               [hrdelegate fingerPresentChanged:NO];
////
////                           }
//                       }
//                   });
    
}



- (float) getPeriod
{
#ifdef DEBUGLOG
    NSLog(@"getPeriod");
#endif
    
    if (!dataReady)
        return -1;
    
    return lastPeriod;
}


- (void) willResignActive
{
    dispatch_sync(cameraQueue, ^{
#ifdef DEBUGLOG
        NSLog(@"willResignActive");
#endif
        //    [accelerometer stopAccelerometer];
        [session beginConfiguration];
        [device lockForConfiguration:nil];
        
        if ([device hasTorch]) {
            if([device isTorchModeSupported:AVCaptureTorchModeOff]){
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        [device unlockForConfiguration];
        [session commitConfiguration];
        [session stopRunning];
        //    [logger stopLogging];
        //    logger = nil;
        cameraDistiller = nil;
        session = nil;
    });
}

+ (BOOL) hasDualCamera
{
    
    AVCaptureDevice *defDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInTelephotoCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    return defDevice == nil ? NO : YES;

}

- (void) didBecomeActive
{
    dispatch_sync(cameraQueue, ^{
        // turn torch back on
#ifdef DEBUGLOG
        NSLog(@"didBecomeActive");
#endif
        NSError *error = nil;
        
        session = [[AVCaptureSession alloc] init];
        [session beginConfiguration];
        
        // Configure the session to produce lower resolution video frames, if your
        // processing algorithm can cope. We'll specify medium quality for the
        // chosen device.
        //session.sessionPreset = AVCaptureSessionPreset352x288;
        session.sessionPreset = AVCaptureSessionPresetLow;
        
        // Find a suitable AVCaptureDevice
        //    device = [AVCaptureDevice
        //              defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([self.class hasDualCamera] && [AVCaptureDeviceDiscoverySession class])
        {
            AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTelephotoCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];

            if  ([discoverySession.devices count] > 0) {
                device = discoverySession.devices[0];
            } else
            {
                NSLog(@"ERROR, AVCaptureDeviceDiscoverySession was empty while looking for AVCaptureDeviceTypeBuiltInTelephotoCamera on a device that was supposed to have it");
            }
        } else
        {
            for (AVCaptureDevice *d in [AVCaptureDevice devices]) {
                if (d.position == AVCaptureDevicePositionBack && [d hasMediaType:AVMediaTypeVideo])
                    device = d;
            }
        }
        if (device == nil)
        {
            NSLog(@"ERROR, could not find a suitable AVCaptureDevice!");
            return;
        }
        
        //newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: session];
        //UIView *view = [self preview];
        //CALayer *viewLayer = [view layer];
        //[viewLayer setMasksToBounds:YES];
        
        //CGRect bounds = [view bounds];
        //[newCaptureVideoPreviewLayer setFrame:bounds];
        
        //if ([newCaptureVideoPreviewLayer isOrientationSupported]) {
        //    [newCaptureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        //}
        
        //[newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        //[viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
        
        
        
        // Create a device input with the device and add it to the session.
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!input) {
            // TODO: Handling the error appropriately.
            NSLog(@"could not add camera to session");
            return;
        }
        // after this line AVCaptureFormat used to change from 5-240 fps to 3-30
        [session addInput:input];
        
        // Create a VideoDataOutput and add it to the session
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        if (!output)
        {
            // TODO: handle this!
            NSLog(@"could not add capture to session");
            return;
        }
        [session addOutput:output];
        
        [device lockForConfiguration:nil];
        
        if([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            device.exposurePointOfInterest = CGPointMake(0.5, 0.5);
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        //    if([device isExposureModeSupported:AVCaptureExposureModeLocked]){
        //        device.exposurePointOfInterest = CGPointMake(0.5, 0.5);
        //        device.exposureMode = AVCaptureExposureModeLocked;
        //    }
        if([device isFocusModeSupported:AVCaptureFocusModeLocked]){
            device.focusMode = AVCaptureFocusModeLocked;
        }
        if([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]){
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
//        if ([device hasFlash]) {
//            if([device isFlashModeSupported:AVCaptureFlashModeOff]){
//                [device setFlashMode:AVCaptureFlashModeOff];
//            }
//        }
        // ------ set framerate
        //    float minFramerate = 30;
        bool iSiOS7 = NO;
        if ([device respondsToSelector:@selector(setActiveVideoMinFrameDuration:)])
        {
            iSiOS7 = YES;
            AVCaptureDeviceFormat *bestFormat = nil;
            AVFrameRateRange *bestFrameRateRange = nil;
            for ( AVCaptureDeviceFormat *format in [device formats] ) {
                for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
                    if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                        bestFormat = format;
                        bestFrameRateRange = range;
                    }
                }
            }
            if ( bestFormat ) {
                //            if ( [device lockForConfiguration:NULL] == YES ) {
                device.activeFormat = bestFormat;
                device.activeVideoMinFrameDuration = CMTimeMake(1, SAMPLFREQ);
                device.activeVideoMaxFrameDuration = CMTimeMake(1, SAMPLFREQ);
                //                minFramerate = CMTimeGetSeconds(CMTimeMake(1, SAMPLFREQ));
                //                [device unlockForConfiguration];
                //            }
            }
        }
        
        //    NSLog(@"%f",CMTimeGetSeconds(device.activeVideoMaxFrameDuration));
        //    NSLog(@"%f",CMTimeGetSeconds(device.activeVideoMinFrameDuration));
        
        //    NSLog(@"minFramerate=%f", minFramerate);
        
        
        cameraDistiller = [[HRMCameraDataDistiller alloc] initWithCamera:device];
        
        PDDataTee *tee = [[PDDataTee alloc] init];
        tee.delegates = @[ self.streamdelegate, self ];
        cameraDistiller.delegate = tee;
        
        //    logger = [[PDDataLogger alloc] init];
        //    [logger startLogging];
        //
        //    accelerometer = [[AccelerometerHelper alloc] init];
        //    accelerometer.delegate = tee;
        //    [accelerometer startAccelerometer];
        
        // Configure your output.
        dispatch_queue_t queue = dispatch_queue_create("com.BioBeatsWorld.CameraCapture", NULL);
        dispatch_queue_t high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(queue,high);
        [output setSampleBufferDelegate:cameraDistiller queue:queue];
        //    dispatch_release(queue);
        
        // Specify the pixel format
        //    output.videoSettings =
        //    [NSDictionary dictionaryWithObject:
        //     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
        //                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        output.videoSettings =
        @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
        
        // If you wish to cap the frame rate to a known value, such as 15 fps, set
        // minFrameDuration.
        //output.minFrameDuration = CMTimeMake(1, 15);
        if (!iSiOS7)
        {
            AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
            [connection setVideoMaxFrameDuration:CMTimeMake(1, SAMPLFREQ)];
            [connection setVideoMinFrameDuration:CMTimeMake(1, SAMPLFREQ)];
        }
        
        NSLog(@"framerate set to %i", SAMPLFREQ);
        NSLog(@"max framerate duration set to %.8f", CMTimeGetSeconds(device.activeVideoMaxFrameDuration));
        NSLog(@"min framerate duration set to %.8f", CMTimeGetSeconds(device.activeVideoMinFrameDuration));
        
        [session commitConfiguration];
        
        // Start the session running to start the flow of data
        [session startRunning];
        if ([device hasTorch]) {
            if([device isTorchModeSupported:AVCaptureTorchModeOn]){
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setTorchModeOnWithLevel:1 error:nil];
                }
            }
        [device unlockForConfiguration];

        //    NSLog(@"%f",CMTimeGetSeconds(device.activeVideoMaxFrameDuration));
        //    NSLog(@"%f",CMTimeGetSeconds(device.activeVideoMinFrameDuration));
    });
}

- (int) findFramerate
{
    __block int bestFramerate=30;
    
    dispatch_sync(cameraQueue, ^{

        // turn torch back on
    #ifdef DEBUGLOG
        NSLog(@"findFramerate");
    #endif
    //    return  30;
        NSError *error = nil;
        
        session = [[AVCaptureSession alloc] init];
        [session beginConfiguration];
        
        session.sessionPreset = AVCaptureSessionPresetLow;
        
        if ([self.class hasDualCamera] && [AVCaptureDeviceDiscoverySession class])
        {
            AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTelephotoCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            
            if  ([discoverySession.devices count] > 0) {
                device = discoverySession.devices[0];
            } else
            {
                NSLog(@"ERROR, AVCaptureDeviceDiscoverySession was empty while looking for AVCaptureDeviceTypeBuiltInTelephotoCamera on a device that was supposed to have it");
            }
        } else
        {
            for (AVCaptureDevice *d in [AVCaptureDevice devices]) {
                if (d.position == AVCaptureDevicePositionBack && [d hasMediaType:AVMediaTypeVideo])
                    device = d;
            }
        }
        
        bool iSiOS7 = NO;
        if ([device respondsToSelector:@selector(setActiveVideoMinFrameDuration:)])
        {
            iSiOS7 = YES;

            
            [device lockForConfiguration:nil];
            
            float minFramerateDur = 0;
            AVCaptureDeviceFormat *bestFormat = nil;
            AVFrameRateRange *bestFrameRateRange = nil;
            for ( AVCaptureDeviceFormat *format in [device formats] ) {
                for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
                    if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                        bestFormat = format;
                        bestFrameRateRange = range;
                    }
                }
            }
            if ( bestFormat ) {
                if ( [device lockForConfiguration:NULL] == YES ) {
                    device.activeFormat = bestFormat;
                    device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
                    device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
                    minFramerateDur = CMTimeGetSeconds(bestFrameRateRange.minFrameDuration);
                    [device unlockForConfiguration];
                }
            }
    #ifdef DEBUGLOG
            NSLog(@"minFramerateDur=%f", minFramerateDur);
    #endif
            [device unlockForConfiguration];
            bestFramerate = (int) (1.0/minFramerateDur + 0.5);
        }
        [session commitConfiguration];

        session = nil;
    });
    return bestFramerate;
    
}

- (void)logBreathingPhase:(int)phase
{
    [logger logBreathingPhase:phase];
}


@end
