//
//  SerieAnalyser.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/5/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "SerieAnalyzer.h"
#import <Accelerate/Accelerate.h>

@interface SerieAnalyzer()
{
    float *buffer;
    int position;
    int length;
    BOOL bufferReady;
    
    float *average;
    int aSize;
    int aPosition;
}

@end

@implementation SerieAnalyzer

- (id) initWithSize: (int) size
    andAnalysisSize: (int) analysisSize
{
    self = [super init];
    if (self) {
        length = size;
        aSize = analysisSize;
        buffer = (float *) malloc(size * sizeof(float));
        average = (float *) malloc(size * sizeof(float));
        for (int i=0; i<length; i++) {
            buffer[i] = 0;
        }
    }
    return self;
}

- (void)dealloc
{
    free(buffer);
}

- (void)addSample:(float)s
{
    buffer[position] = s;
    position = (position+1)%length;
    if (position == 0)
    {
        bufferReady = YES;
        // analyse all buffer
    }
    
    if (bufferReady)
    {
        
    }
}

- (void) analyse: (int) position
{
    // TODO: do not compute everything again!
    
    // average
    float sum = 0.0;
    for (int i=0; i<aSize; i++) {
        int bufIdx = (position-1-i+length)%length;
        sum += buffer[bufIdx];
    }
    average[aPosition] = sum / ((float)aSize);
    aPosition = (aPosition + 1) % length;

}

@end
