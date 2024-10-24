//
//  CrossCorrelation.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

@interface CrossCorrelation : NSObject<StreamAnalyzer>

- (id) initWithSize: (int) s;

@property (retain, nonatomic) id<StreamAnalyzer> delegateCorrelation;
@property (retain, nonatomic) id<StreamAnalyzer> delegatePhase;

@property int producedCorrelationStreamID;
@property int producedPhaseStreamID;

@end
