//
//  DiscardHead.m
//  HeartDetectorEngine
//
//  Created by Davide Morelli on 28/11/15.
//  Copyright © 2015 BioBeats. All rights reserved.
//

#import "DiscardHead.h"

@interface DiscardHead()
{
    int size;
    int count;
    BOOL ready;
}
@end

@implementation DiscardHead

- (id) initWithSize: (int) s
{
    self = [super init];
    if (self) {
        size = s;
        count = 0;
        ready = NO;
    }
    return self;
}

- (void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    if (!ready)
    {
        count++;
        if (count > size)
            ready = YES;
    } else
    {
        [self.delegate addSampleWithTime:t value:v andStreamID:ID];
    }
}

@end
