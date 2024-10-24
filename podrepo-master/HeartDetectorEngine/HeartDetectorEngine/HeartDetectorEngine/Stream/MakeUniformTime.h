//
//  MakeUniformTime.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "StreamAnalyzer.h"

@interface MakeUniformTime : NSObject<StreamAnalyzer>

- (id) initWithSamplerate: (float) Hz;

@property (retain, nonatomic) id<StreamAnalyzer> delegate;

@end
