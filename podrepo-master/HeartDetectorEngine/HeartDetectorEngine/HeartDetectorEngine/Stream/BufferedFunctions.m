//
//  BufferedFunctions.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "BufferedFunctions.h"
#import <Accelerate/Accelerate.h>


@interface BufferedFunctions()
{
    
    int size;
    CMTime *timestamps;
    float *values;
    float currSum;
    int position;
    BOOL ready;
    
    int function;
    
    // wabp
    float threshold;
    CMTime prev;
    BOOL first;
    float lastP;
}

-(void)detrendEnd:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)averageMiddle:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)normalize:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)invert:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)delay:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)sumslope:(CMTime)t andValue:(float)v andStreamID:(int)id;
-(void)wabp:(CMTime)t andValue:(float)v andStreamID:(int)id;

@end



@implementation BufferedFunctions

@synthesize delegate;
@synthesize maxNormGain;
@synthesize minNormDiff;

- (id)init
{
    return [self initWithType:0 andSize:1];
}


- (id) initWithType: (int) t
            andSize: (int) s
{
    self = [super init];
    if (self) {
        size = s;
        function = t;
        values = malloc(size*sizeof(float));
        timestamps = malloc(size*sizeof(CMTime));
        position = 0;
        ready = NO;
        currSum = 0.0;
        for (int i=0; i<size; i++) {
            values[i]=0.0;
        }
        first = NO;
        lastP = -1.0;
        self.maxNormGain = -1.0;
        self.minNormDiff = 0.0;
    }
    return self;
}

-(void)dealloc
{
    free(timestamps);
    free(values);
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    switch (function) {
        case 0:
            [self averageMiddle:t andValue:v andStreamID:ID];
            break;
        case 1:
            [self detrendEnd:t andValue:v andStreamID:ID];
            break;
        case 2:
            [self normalize:t andValue:v andStreamID:ID];
            break;
        case 3:
            [self invert:t andValue:v andStreamID:ID];
            break;
        case 4:
            [self delay:t andValue:v andStreamID:ID];
            break;
        case 5:
            [self sumslope:t andValue:v andStreamID:ID];
            break;
        case 6:
            [self wabp:t andValue:v andStreamID:ID];
            break;
            
        default:
            break;
    }
}

-(void)delay:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // substitute it
    if (ready)
    {
        [delegate addSampleWithTime:timestamps[position] value:values[position]  andStreamID:ID];
    }
    
    values[position] = v;
    timestamps[position] = t;
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
    }
}

-(void)detrendEnd:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // take the old one out
    currSum -= values[position];
    // substitute it
    values[position] = v;
    timestamps[position] = t;
    // recalculate the average
    currSum += v;
    if (ready)
    {
        float newaverage = currSum / ((float)size);
        [delegate addSampleWithTime:t value:v-newaverage  andStreamID:ID];
    }
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
    }
}

-(void)averageMiddle:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // take the old one out
    currSum -= values[position];
    // substitute it
    values[position] = v;
    timestamps[position] = t;
    // recalculate the average
    currSum += v;
    if (ready)
    {
        float newaverage = currSum / ((float)size);
        // the time of the average is half window ago
        CMTime refTimestamp = timestamps[(position + size/2)%size];
        [delegate addSampleWithTime:refTimestamp value:newaverage andStreamID:ID];
    }
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
    }
}

-(void)normalize:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // substitute it
    values[position] = v;
    timestamps[position] = t;
    if  (ready)
    {
        float max;
        float min;
        vDSP_maxv(values, 1, &max, size);
        vDSP_minv(values, 1, &min, size);
        float factor = 0.0;
        if (fabsf(max) > 0 || fabsf(min) > 0.0)
        {
            factor = 1.0/MAX(fabsf(max), fabsf(min));
        }
        if (max - min < self.minNormDiff)
            factor = 1.0;
        if (self.maxNormGain > 0.0) {
            factor = MIN(self.maxNormGain, factor);
        }
        [delegate addSampleWithTime:t value:(v*factor) andStreamID:ID];
    }
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
    }
}

-(void)invert:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    [delegate addSampleWithTime:t value:-v andStreamID:ID];
}

- (void)sumslope:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // substitute it
    values[position] = v;
    timestamps[position] = t;
    if  (ready)
    {
        // perform sum slope
        float sum = 0.0;
        for (int i=0; i<(size-1); i++)
        {
            float delta = values[(position - i + size) % size] - values[(position - i - 1 + size) % size];
            if (delta > 0)
                sum += delta;
        }
        [delegate addSampleWithTime:t value:(sum) andStreamID:ID];
    }
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
    }
}

-(void)wabp:(CMTime)t andValue:(float)v andStreamID:(int)ID
{
    // substitute it
    values[position] = v;
    timestamps[position] = t;
    if  (ready)
    {
        float max;
        vDSP_maxv(values, 1, &max, size);
        threshold = max / 3.0;
        if (v > threshold && values[(position-1+size)%size]<threshold)
        {
            // go back to where the slope started
            int count = 0;
            BOOL found = NO;
            int pos = position;
            while (count < size && !found)
            {
                if (values[pos] - values[(pos + size - 1) % size] < threshold*0.1)
                {
                    found = YES;
                } else
                {
                    pos = (pos - 1 + size) % size;
                    count++;
                }
            }
            CMTime curr = timestamps[pos];
            CMTime diff = CMTimeSubtract(curr, prev);
            float period = CMTimeGetSeconds(diff);
            if (!first)
            {
                // that was the first detected pulse
                first = YES;
                prev = curr;
            } else if (period > 0.4)
            {
                if (period < 1.8)
                {
                    // lastP = 1.0 by convention when not initialized
                    if (lastP < 0.0)
                    {
                        // this is the first beat
                        // just accept it
                        // new pulse detected!
                        prev = curr;
                        lastP = period;
                        // update threshold
                        //                float diffThreshold = v - threshold;
                        //                threshold += diffThreshold * 0.2; // adapt (faster than it's done in the paper)
                        //                NSLog(@"WABP: Pulse! period = %f", period);
                        // spread the word
                        [delegate addSampleWithTime:curr value:period andStreamID:STREAM_TACHOGRAM];
                        
                    } else
                    {
                        // this is not the first beat, accept it only if near to previous
                        if (fabs(lastP - period)/MAX(lastP, period) < 0.3)
                        {
                            // new pulse detected!
                            prev = curr;
                            lastP = period;
                            // update threshold
                            //                float diffThreshold = v - threshold;
                            //                threshold += diffThreshold * 0.2; // adapt (faster than it's done in the paper)
                            //                NSLog(@"WABP: Pulse! period = %f", period);
                            // spread the word
                            [delegate addSampleWithTime:curr value:period andStreamID:STREAM_TACHOGRAM];
                        } else
                        {
                            // period was more than 30% different than previous
                            // it could happen during deep breathing
                            // but just discard for now
                            NSLog(@"skipping, more than 30 percent away from previous");
                            // also reset last period
                            lastP = -1.0;
                        }

                    }
                } else
                {
                    // lost a pulse.. restart
                    prev = curr;
                    NSLog(@"skipping, too long");
                    // also reset last period
                    lastP = -1.0;
                }
            } else {
                NSLog(@"skipping, too short");
                // also reset last period
                lastP = -1.0;
            }
        }
    }
    // prepare position for next
    position = (position + 1 ) % size;
    if (position == 0 && !ready)
    {
        // buffer has been filled
        ready = YES;
        //        // set initial value for threshold
        //        float sum = 0.0;
        //        for (int i=0; i<size; i++)
        //        {
        //            sum += values[i];
        //        }
        //        float average = sum / ((float) size);
        //        threshold = 3.0 * average;
    }
}

@end
