//
//  SignalGenerator.m
//  HeartDetectorEngine
//
//  Created by Davide Morelli on 10/10/15.
//  Copyright © 2015 BioBeats. All rights reserved.
//

#import "SignalGenerator.h"

@implementation SignalGenerator
{
    CMTime currTimestamp;
    CMTime frameDuration;
    NSUInteger n_samples;
    float *data;
    int streamID;
    
    int lastPos;
    BOOL moreSamples;
}

- (instancetype) initWithFakeData: (float *) buffer
                  numberOfSamples: (NSUInteger) nSamples
                    andSampleRate: (float) sampleRate
                      andStreamID:(int)stream;

{
    self = [super init];
    if (self)
    {
        frameDuration = CMTimeMake(1, sampleRate);
        currTimestamp = CMTimeMakeWithSeconds(0, sampleRate);
        n_samples = nSamples;
        data = buffer;
        streamID = stream;
        moreSamples = YES;
    }
    return self;
}

- (void)generateSignal
{
    for (NSUInteger i = 0; i < n_samples; i++) {
//        if (data[i] == 0)
//        {
//            NSLog(@"impulse");
//        }
        [self.delegate addSampleWithTime:currTimestamp value:data[i] andStreamID:streamID];
        currTimestamp = CMTimeAdd(currTimestamp, frameDuration);
    }
}

- (BOOL)generateSampleAtTime:(CMTime)t
{
    while (CMTimeCompare(currTimestamp, t) < 0 && moreSamples) {
        moreSamples = [self generateSample];
    }
    return moreSamples;
}

- (BOOL)generateSample
{
//    NSLog(@"generate sample %f at time %f for stream %i", data[lastPos], CMTimeGetSeconds(currTimestamp), streamID);
    
    [self.delegate addSampleWithTime:currTimestamp value:data[lastPos++] andStreamID:streamID];
    currTimestamp = CMTimeAdd(currTimestamp, frameDuration);
    return lastPos < n_samples;
}

- (void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    // nop
}

@end
