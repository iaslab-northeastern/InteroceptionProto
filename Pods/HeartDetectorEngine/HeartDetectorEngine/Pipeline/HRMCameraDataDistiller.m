//
//  HRMCameraDataDistiller.m
//  HRMeter
//
//  Created by Andrea Canciani on 4/19/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "HRMCameraDataDistiller.h"

@implementation HRMCameraDataDistiller

@synthesize delegate = _delegate;

#define WINSIZE 60
#define NORM 0

- (id)initWithCamera:(AVCaptureDevice *)camera
{
    self = [super init];
    if (self) {
        self.size = -1;
        _window = calloc(sizeof(*_window), WINSIZE);
        _total = 0;
        _device = camera;
        _validCount = 0;
    }

    return self;
}

- (int)size
{
    return _size;
}

- (void)setSize:(int)v
{
    _size = v;

    if (_size % 2 != 0)
        _size += 1;

    if (_size <= 0)
        _size = 50;

    _halfSize = _size / 2;
    _invArea = 1.0 / (_size * (float) _size);
}

- (void)appendValue:(uint32_t)v
{
    _total -= _window[_idx];
    _window[_idx] = v;
    _total += v;

    _idx++;
    if (_idx == WINSIZE)
        _idx = 0;

    _validCount++;
    if (_validCount > WINSIZE)
        _validCount = WINSIZE;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{

    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);

    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t bytesPerPixel = sizeof(unsigned long);

    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

    void *imageCenter = baseAddress;
    imageCenter += bytesPerRow * height / 2;
    imageCenter += bytesPerPixel * width / 2;

    unsigned int r_sum, g_sum, b_sum;
    r_sum = g_sum = b_sum = 0;

    for (int y = -_halfSize; y < _halfSize; y++) {
        unsigned long *rowCenter = imageCenter + bytesPerRow * y;
        for (int x = -_halfSize; x < _halfSize; x++) {
            unsigned long pixel = rowCenter[x];
            b_sum += pixel & 0xFF;
            pixel >>= 8;
            g_sum += pixel & 0xFF;
            pixel >>= 8;
            r_sum += pixel & 0xFF;
        }
    }

    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);


    float r = (r_sum ) * _invArea;
    float g = (g_sum ) * _invArea;
    float b = (b_sum ) * _invArea;
    
    [_delegate addSampleForTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        withRed:r
                      withGreen:g
                           withBlue:b];
    
}

@end
