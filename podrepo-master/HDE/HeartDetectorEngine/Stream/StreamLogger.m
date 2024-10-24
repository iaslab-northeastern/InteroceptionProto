//
//  StreamLogger.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "StreamLogger.h"

@interface StreamLogger()
{
}


@end

@implementation StreamLogger

@synthesize name;

- (id) initWithName: (NSString *) n
{

    self = [super init];
    if (self) {
        self.name = n;
    }
    return self;
}


-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    NSLog(@",%i,%@,%f,%f", ID, self.name, CMTimeGetSeconds(t), v);
}
@end
