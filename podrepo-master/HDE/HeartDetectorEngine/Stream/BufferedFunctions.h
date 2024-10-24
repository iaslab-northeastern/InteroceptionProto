//
//  BufferedFunctions.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

@interface BufferedFunctions : NSObject<StreamAnalyzer>

// types are:
#define BUFFERED_AVERAGE_MID 0
#define BUFFERED_DETREND 1
#define BUFFERED_NORMALISE 2
#define BUFFERED_INVERT 3
#define BUFFERED_DELAY 4
#define BUFFERED_SUM_SLOPE_FUNCTION 5
#define BUFFERED_WABP 6

- (id) initWithType: (int) t
            andSize: (int) s;

@property (retain, nonatomic) id<StreamAnalyzer> delegate;

@property float maxNormGain;
@property float minNormDiff;


@end
