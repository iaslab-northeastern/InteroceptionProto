//
//  StreamTee.h
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

@interface StreamTee : NSObject<StreamAnalyzer>

@property (strong, nonatomic) NSArray *delegates;

- (id) initWithDelegates:(NSArray *)delegates;

@end
