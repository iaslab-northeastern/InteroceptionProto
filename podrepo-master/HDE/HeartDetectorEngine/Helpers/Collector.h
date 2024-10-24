//
//  Collector.h
//  HeartDetectorEngine
//
//  Created by Davide Morelli on 13/01/16.
//  Copyright © 2016 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

// a simple object that collect all values in an array
@interface Collector : NSObject<StreamAnalyzer>

@property (readonly) NSMutableArray  *samples;

- (instancetype)initWithSize: (unsigned int) size;

-(void) resetCollector;

@end
