//
//  HRMCameraDataDistiller.h
//  HRMeter
//
//  Created by Andrea Canciani on 4/19/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "HRMSampleStreamAnalyzer.h"

@interface HRMCameraDataDistiller : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureDevice *_device;

    uint32_t *_window;
    uint32_t _total;
    int _idx;
    int _validCount;

    int _size;
    int _halfSize;
    float _invArea;
}

@property (strong, nonatomic) id<HRMSampleStreamAnalyzer> delegate;
@property (nonatomic) int size;

-(id) initWithCamera:(AVCaptureDevice *)camera;

@end
