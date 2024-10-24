//
//  DiscardHead.h
//  HeartDetectorEngine
//
//  Created by Davide Morelli on 28/11/15.
//  Copyright © 2015 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamAnalyzer.h"

@interface DiscardHead : NSObject<StreamAnalyzer>

- (id) initWithSize: (int) s;

@property (retain, nonatomic) id<StreamAnalyzer> delegate;

@end
