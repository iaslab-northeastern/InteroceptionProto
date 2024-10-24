//
//  Collector.m
//  HeartDetectorEngine
//
//  Created by Davide Morelli on 13/01/16.
//  Copyright © 2016 BioBeats. All rights reserved.
//

#import "Collector.h"
#import <Accelerate/Accelerate.h>

@interface Collector()
{
    unsigned int position;
    float *buffer;
    unsigned int size;
}

@end

@implementation Collector

@synthesize samples = _samples;

- (instancetype)initWithSize:(unsigned int)s
{
    self = [super init];
    if (self) {
        position = 0;
        size = s;
        buffer = (float*) calloc(size, sizeof(float));
    }
    return self;
}

- (void)dealloc
{
    free(buffer);
}

- (void)resetCollector
{
    float a = 0;
    vDSP_vfill(&a, buffer, 1, size);
    position = 0;
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    if (position < size)
    {
        buffer[position++] = v;
    }
}

- (NSArray *) samples
{
    if (size < 1 || buffer == nil || position > size)
        return @[];
    NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:size];
    for (unsigned int i = 0; i<position-1; i++) {
        a[i] = [NSNumber numberWithFloat:buffer[i]];
    }
    return a;
}

@end
