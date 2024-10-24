//
//  PipelineStageToStream.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "PipelineStageToStream.h"

@implementation PipelineStageToStream

@synthesize cameraDelegate;
@synthesize accelerometerDelegate;
@synthesize controlSignalDelegate;

-(void)addAccelerationForTime:(CMTime)t withX:(float)x withY:(float)y withZ:(float)z
{
    [accelerometerDelegate addSampleWithTime:t value:y andStreamID:STREAM_ACCELEROMETER];
}

-(void)addSampleForTime:(CMTime)t withRed:(float)r withGreen:(float)g withBlue:(float)b
{
    float average = (r+b+g)/3.0;
    [cameraDelegate addSampleWithTime:t value:average andStreamID:STREAM_PPG];
}

- (void) addControlSignalForTime:(CMTime) t
                       withPhase:(float) p
{
    // map [0, 1.0] to [-1.0, 1.0]
    [controlSignalDelegate addSampleWithTime:t value:(p*2.0-1.0) andStreamID:STREAM_CONTROL_SIGNAL];
}


@end
