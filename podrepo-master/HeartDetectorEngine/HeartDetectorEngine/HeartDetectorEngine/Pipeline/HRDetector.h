//
//  HRDetector.h
//  BreatingEngine
//
//  Created by Davide Morelli on 8/16/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRMSampleStreamAnalyzer.h"
#import "HREventsDelegate.h"
#import "StreamAnalyzer.h"

@interface HRDetector : NSObject<StreamAnalyzer>

@property (strong, nonatomic) id<HREventsDelegate> delegate;

@property NSMutableArray * HRperiods;

- (void) fingerPresent: (BOOL) isFingerPresent;

- (id) initWithPeriod: (float) p;

@end
