//
//  PipelineStageToStream.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRMSampleStreamAnalyzer.h"
#import "StreamAnalyzer.h"

@interface PipelineStageToStream : NSObject<HRMSampleStreamAnalyzer>

@property (strong, nonatomic) id<StreamAnalyzer> cameraDelegate;
@property (strong, nonatomic) id<StreamAnalyzer> accelerometerDelegate;
@property (strong, nonatomic) id<StreamAnalyzer> controlSignalDelegate;

@end
