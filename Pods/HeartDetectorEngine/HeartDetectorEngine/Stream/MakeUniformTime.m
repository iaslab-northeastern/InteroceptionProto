//
//  MakeUniformTime.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "MakeUniformTime.h"


@interface MakeUniformTime()
{
    CMTime last;
    CMTime from_timestamp;
    CMTime to_timestamp;
    float from_value;
    float to_value;
    CMTime time_increment;
}

@end

@implementation MakeUniformTime

@synthesize delegate;

- (id) init
{
    return [self initWithSamplerate:10.0 ];
}

- (id) initWithSamplerate: (float) Hz
{
    self = [super init];
    if (self) {
        time_increment = CMTimeMakeWithSeconds(1.0/Hz, 1000);
        from_value  =0.0;
        to_value = 0.0;
        from_timestamp = CMTimeMakeWithSeconds(0.0, 1000);
        to_timestamp = CMTimeMakeWithSeconds(0.0, 1000);
    }
    return self;
}

- (void) addSampleWithTime: (CMTime) t
                  value: (float) v
               andStreamID:(int)ID
{
//    NSLog(@"make uniform called");
    // update values
    from_timestamp = to_timestamp;
    from_value = to_value;
    to_timestamp = t;
    to_value = v;
    // skip the first one
    if (CMTimeGetSeconds(from_timestamp)>0)
    {
        // calculate range
        CMTime new_timestamp = CMTimeAdd(last, time_increment);
        float range_t = CMTimeGetSeconds(CMTimeSubtract(to_timestamp, from_timestamp));
        float range_v = to_value - from_value;
        // while this sample is earlier than the end
        while (CMTimeCompare(new_timestamp, to_timestamp)<=0)
        {
            // calculate distance from start of this sample
            float x_delta = CMTimeGetSeconds(CMTimeSubtract(new_timestamp, from_timestamp));
            float x_delta_perc = x_delta / range_t;
            float new_value = from_value + x_delta_perc*range_v;
            // generate new sample
//            NSLog(@"make uniform generated a sample");
            [delegate addSampleWithTime:new_timestamp value:new_value andStreamID:ID];
            // prepare for next
            last = new_timestamp;
            new_timestamp = CMTimeAdd(last, time_increment);
        }
    
    } else
    {
        last = to_timestamp;
    }
    
}

@end
