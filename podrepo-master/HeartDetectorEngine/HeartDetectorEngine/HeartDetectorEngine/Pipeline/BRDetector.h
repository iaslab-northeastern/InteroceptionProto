//
//  BRDetector.h
//  BreatingEngine
//
//  Created by Davide Morelli on 8/16/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRMSampleStreamAnalyzer.h"
#import "BREventsDelegate.h"
#import "StreamAnalyzer.h"

@interface BRDetector : NSObject<HRMSampleStreamAnalyzer, StreamAnalyzer>

@property NSMutableArray * breathQuality;

- (id) initWithCamera:(BOOL) usingCamera
     andAccelerometer: (BOOL) usingAccelerometer;

@property (strong, nonatomic) id<BREventsDelegate> delegate;




@end
