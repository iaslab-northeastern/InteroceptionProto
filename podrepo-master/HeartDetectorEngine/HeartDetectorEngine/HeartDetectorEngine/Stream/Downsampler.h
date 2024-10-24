//
//  Downsampler.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

@interface Downsampler : NSObject<StreamAnalyzer>

- (id) initWithDownsamplingFactor: (int) factor;

@property (retain, nonatomic) id<StreamAnalyzer> delegate;

@end
