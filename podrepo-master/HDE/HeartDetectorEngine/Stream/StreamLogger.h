//
//  StreamLogger.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"


@interface StreamLogger : NSObject<StreamAnalyzer>

- (id) initWithName: (NSString *) n;

@property NSString *name;
@end
