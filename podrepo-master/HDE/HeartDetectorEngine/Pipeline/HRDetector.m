//
//  HRDetector.m
//  BreatingEngine
//
//  Created by Davide Morelli on 8/16/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "HRDetector.h"

@interface HRDetector()
{
    BOOL finger;
    BOOL firstAfterNoFinger;
    int currIndex;
    float period;
}

@property NSMutableArray *times;

@end


@implementation HRDetector

@synthesize delegate = _delegate;
@synthesize HRperiods;
@synthesize times;

- (instancetype) init
{
    return [self initWithPeriod:10.0];
}

- (id) initWithPeriod: (float) p
{
    self = [super init];
    if (self) {
        self.HRperiods = [[NSMutableArray alloc] init];
        self.times = [[NSMutableArray alloc] init];
        currIndex = 0;
        period = p;
    }
    return self;
}


- (void) fingerPresent: (BOOL) isFingerPresent
{
    if (finger != isFingerPresent)
    {
        if (finger == NO)
        {
            firstAfterNoFinger = YES;
        }
        finger = isFingerPresent;
        [self.delegate fingerPresentChanged:isFingerPresent];
    }
}



- (void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    if (firstAfterNoFinger)
    {
        // discard the first, as it's probably wrong
        firstAfterNoFinger = NO;
    } else
    {
        if (v < .3)
        {
            // discard!
        } else if (v > 1.8)
        {
            // period doesn't look good.. discard? split?
        } else
        {
            // period looks fine, just send it
            [HRperiods addObject:[NSNumber numberWithFloat:v]];
            [times addObject:[NSNumber numberWithFloat:CMTimeGetSeconds(t)]];
            // evaluate the buffer
            float max = 0.0;
            float min = 99999.0;
            float thisT = CMTimeGetSeconds(t);
            float sum = 0.0;
            for (int i=0; i<[HRperiods count]; i++) {
                sum += [[HRperiods objectAtIndex:i] floatValue];
            }
            for (int i=currIndex; i<[HRperiods count]; i++) {
                float diff = thisT - [[self.times objectAtIndex:i] floatValue];
                if (diff>period)
                {
                    currIndex++;
                } else
                {
                    float thisV = [[HRperiods objectAtIndex:i] floatValue];
                    if (thisV < min)
                        min = thisV;
                    if (thisV > max)
                        max = thisV;
                }
            }
            float avg = sum / ((float)[HRperiods count]);
            [self.delegate beatDetectedWithInstantBPM:60.0/v andAverageBPM:60.0/avg ];
            [self.delegate reportHRVActivation:((max-min)/min) withMaxPeriod:max andMinPeriod:min];
        }
    }
}

@end
