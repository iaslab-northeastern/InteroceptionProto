//
//  PDDataTee.h
//  PulseDetector
//
//  Created by Andrea Canciani on 7/17/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HRMSampleStreamAnalyzer.h"

@interface PDDataTee : NSObject<HRMSampleStreamAnalyzer>

@property (strong, nonatomic) NSArray *delegates;

@end

