//
//  SerieAnalyser.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/5/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerieAnalyzer : NSObject

- (id) initWithSize: (int) size
    andAnalysisSize: (int) analysisSize;

- (void) addSample: (float) s;

- (float) average;

- (void) analyse: (int) position;

@end
