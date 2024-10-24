//
//  StreamTee.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "StreamTee.h"

@implementation StreamTee

@synthesize delegates;

- (id) initWithDelegates:(NSArray *)delegates
{
    self = [super init];
    if (self) {
        self.delegates = delegates;
    }
    return self;
    
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID 
{
    
    for (id<StreamAnalyzer> delegate in delegates) {
        @autoreleasepool {
            [delegate addSampleWithTime:t value:v andStreamID:ID];
        }
    }
    
}
@end
