//
//  Downsampler.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "Downsampler.h"

@interface Downsampler()
{
    int f;
    float state;
    int count;
}
@end

@implementation Downsampler

@synthesize delegate;

- (id)init
{
    return [self initWithDownsamplingFactor:1];
}

- (id)initWithDownsamplingFactor:(int)factor
{
    self = [super init];
    if (self) {
        f = factor;
    }
    return self;
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    count++;
    state += v/((float)f);
    if (count == f)
    {
        [delegate addSampleWithTime:t value:state andStreamID:ID];
        count = 0;
        state = 0.0;
    }
}

@end
