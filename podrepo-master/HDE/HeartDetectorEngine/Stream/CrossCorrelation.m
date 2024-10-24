//
//  CrossCorrelation.m
//  PulseDetector
//
//  Created by Davide Morelli on 9/6/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "CrossCorrelation.h"

#import <Accelerate/Accelerate.h>


#define DEBUGLOG 0


@interface CrossCorrelation()
{
    CMTime lastTimestamp;
    
    int size;
    float *valuesControl;
    float *normControl;
    float *valuesSignal;
    float *convolution;
    float *convolutionNorm;
    float *convolutionNormControl;
    int positionControl;
    int positionSignal;
    BOOL readyControl;
    BOOL readySignal;
    
    FFTSetup setup;
    DSPSplitComplex complexSignal;
    DSPSplitComplex complexControl;
    DSPSplitComplex complexNormControl;
    int lnSize;
    int sizeOver2;
}

- (void) crossCorrelate;

@end



@implementation CrossCorrelation

@synthesize delegateCorrelation;
@synthesize delegatePhase;

@synthesize producedCorrelationStreamID;
@synthesize producedPhaseStreamID;

- (id)init
{
    return [self initWithSize:64];
}


- (id) initWithSize: (int) s
{
    self = [super init];
    if (self) {
        size = s;
        valuesControl = malloc(size*sizeof(float));
        normControl = malloc(size*sizeof(float));
        valuesSignal = malloc(size*sizeof(float));
        convolution = malloc(size*sizeof(float));
        convolutionNorm = malloc(size*sizeof(float));
        convolutionNormControl = malloc(size*sizeof(float));
        positionSignal = 0;
        readySignal = NO;
        positionControl = 0;
        readyControl = NO;
        lnSize = (int)log2(s);
        sizeOver2 = size/2;
        setup = vDSP_create_fftsetup(lnSize, kFFTRadix2);
        complexControl.imagp = malloc(sizeOver2 * sizeof(float));
        complexControl.realp = malloc(sizeOver2 * sizeof(float));
        complexNormControl.imagp = malloc(sizeOver2 * sizeof(float));
        complexNormControl.realp = malloc(sizeOver2 * sizeof(float));
        complexSignal.imagp = malloc(sizeOver2 * sizeof(float));
        complexSignal.realp = malloc(sizeOver2 * sizeof(float));
        
    }
    return self;
}

-(void)dealloc
{
    free(valuesControl);
    free(normControl);
    free(valuesSignal);
    free(convolution);
    free(convolutionNorm);
    free(convolutionNormControl);
    free(complexSignal.imagp);
    free(complexSignal.realp);
    free(complexControl.realp);
    free(complexControl.imagp);
    free(complexNormControl.realp);
    free(complexNormControl.imagp);
    vDSP_destroy_fftsetup(setup);
}

-(void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID 
{
//    // test autocorrelation
//    if (ID != 0)
//        return;
//    // control signal
//    valuesControl[positionControl] = v;
//    normControl[positionControl] = v > 0 ? 1.0 : -1.0 ;
//    positionControl = (positionControl + 1) % size;
//    if (positionControl == 0 && !readyControl)
//    {
//        readyControl = YES;
//    }
//    // other signal
//    valuesSignal[positionSignal] = v;
//    positionSignal = (positionSignal + 1) % size;
//    if (positionSignal == 0 && !readySignal)
//    {
//        readySignal = YES;
//    }
//    if (readyControl && readySignal)
//    {
//        [self naiveCrossCorrelate];
//        [self crossCorrelate];
//    }
//    return;
//
    
    lastTimestamp = t;
    
    if (ID == 0)
    {
//        NSLog(@"control signal: %f %f", CMTimeGetSeconds(t), v);
        // control signal
        valuesControl[positionControl] = v;
        normControl[positionControl] = v > 0 ? 1.0 : -1.0 ;
        positionControl = (positionControl + 1) % size;
        if (positionControl == 0 && !readyControl)
        {
            readyControl = YES;
        }
    } else
    {
//        NSLog(@"other signal: %f %f", CMTimeGetSeconds(t), v);
        // other signal
        valuesSignal[positionSignal] = v;
        positionSignal = (positionSignal + 1) % size;
        if (positionSignal == 0 && !readySignal)
        {
            readySignal = YES;
        }
    }
     
    
    if (readyControl && readySignal)
    {
        [self naiveCrossCorrelate];
//        [self crossCorrelate];
    }
}


- (void) naiveCrossCorrelate
{
    /*
let naivecorr (A:float[]) (B:float[]) =
     let N = A.Length
     let C = A |> Array.copy
     for i in 0..N-1 do
         C.[i] <- 0.0
         for k in 0..N-1 do
             C.[i] <- C.[i] + A.[(i+k) % N] * B.[k]
     C
     */
    
#if DEBUGLOG
    for (int i=0; i<size; i++) {
        NSLog(@"valuesControl[%i]=%f", i, valuesControl[i]);
    }
    for (int i=0; i<size; i++) {
        NSLog(@"normControl[%i]=%f", i, normControl[i]);
    }
    for (int i=0; i<size; i++) {
        NSLog(@"valuesSignal[%i]=%f", i, valuesSignal[i]);
    }
#endif
    
    for (int i=0; i<size; i++) {
        convolutionNormControl[i] = 0.0;
        for (int j=0; j<size; j++) {
            convolutionNormControl[i] += normControl[(i+j)%size]*valuesControl[j];
        }
    }
    
#if DEBUGLOG
    for (int i=0; i<size; i++) {
        NSLog(@"norm convolution[%i]=%f", i, convolution[i]);
    }
#endif

    
    float norm = convolutionNormControl[0];

    for (int i=0; i<size; i++) {
        convolution[i] = 0.0;
        for (int j=0; j<size; j++) {
            convolution[i] += valuesSignal[(i+j)%size]*valuesControl[j];
        }
    }
    
#if DEBUGLOG
    for (int i=0; i<size; i++) {
        NSLog(@"real convolution[%i]=%f", i, convolution[i]);
    }
#endif

    for (int i=0; i<size; i++) {
        convolutionNorm[i] = convolution[i]/norm;
    }

#if DEBUGLOG
    for (int i=0; i<size; i++) {
        NSLog(@"normalized convolution[%i]=%f", i, convolution[i]);
    }
#endif

    // find peak
    int bestIndex = 0;
    float bestAutocorrelation = -2.0;
    for (int i=1; i<size; i++) {
        if (convolutionNorm[i]>bestAutocorrelation)
        {
            bestAutocorrelation = convolutionNorm[i];
            bestIndex = i;
        }
//        if (convolutionNorm[size-i]>bestAutocorrelation)
//        {
//            bestAutocorrelation = convolutionNorm[size-i];
//            bestIndex = size-i;
//        }
    }
    float phase = fmodf((((float)bestIndex)/((float)size) + 0.5), 1.0) - 0.5;
//    NSLog(@"naive peak %f phase %f norm %f", bestAutocorrelation, phase, norm);
    
//    if (bestAutocorrelation > 1.0)
//    {
//        // WTF?
//        for (int i=0; i<size; i++) {
//            NSLog(@"valuesControl[%i]=%f", i, valuesControl[i]);
//        }
//        for (int i=0; i<size; i++) {
//            NSLog(@"normControl[%i]=%f", i, normControl[i]);
//        }
//        for (int i=0; i<size; i++) {
//            NSLog(@"valuesSignal[%i]=%f", i, valuesSignal[i]);
//        }
//        for (int i=0; i<size; i++) {
//            NSLog(@"convolutionNormControl[%i]=%f", i, convolutionNormControl[i]);
//        }
//        for (int i=0; i<size; i++) {
//            NSLog(@"convolution[%i]=%f", i, convolution[i]);
//        }
//        for (int i=0; i<size; i++) {
//            NSLog(@"convolutionNorm[%i]=%f", i, convolutionNorm[i]);
//        }
//
//    }

    [delegateCorrelation addSampleWithTime:lastTimestamp value:bestAutocorrelation andStreamID:self.producedCorrelationStreamID];
    [delegatePhase addSampleWithTime:lastTimestamp value:phase andStreamID:self.producedPhaseStreamID];
    
}

 -(void)crossCorrelate
{
    
    // -------------- calculate norm --------------------
    
    // convert from real to complex
    vDSP_ctoz((COMPLEX *)normControl, 2, &complexSignal, 1, sizeOver2);
    vDSP_ctoz((COMPLEX *)valuesControl, 2, &complexControl, 1, sizeOver2);
    
    // FFT
    vDSP_fft_zrip(setup, &complexSignal, 1, lnSize, FFT_FORWARD);
    vDSP_fft_zrip(setup, &complexControl, 1, lnSize, FFT_FORWARD);
    
    // convolve signal with complex cojugate of control
    //vDSP_zvconj(&complexControl, 1, &complexControl, 1, sizeOver2);
    vDSP_zvcmul(&complexSignal, 1, &complexControl, 1, &complexSignal, 1, sizeOver2);
    
    // set first complex value to 0
    complexSignal.imagp[0] = 0.0;
    complexSignal.realp[0] = 0.0;
    
    // inverse FFT
    vDSP_fft_zrip(setup, &complexSignal, 1, lnSize, FFT_INVERSE);
    
    // back to real
    vDSP_ztoc(&complexSignal, 1, (COMPLEX *)convolution, 2, sizeOver2);
    
    // normalize
    float scale = 1.f/convolution[0];
    vDSP_vsmul(convolution, 1, &scale, convolution, 1, size);
    
    float norm = 1.0/convolution[0];
    
    
    // ------------------- real correlation --------------------
    // convert from real to complex
    vDSP_ctoz((COMPLEX *)valuesSignal, 2, &complexSignal, 1, sizeOver2);
//    vDSP_ctoz((COMPLEX *)valuesControl, 2, &complexControl, 1, sizeOver2);
    
    // FFT
    vDSP_fft_zrip(setup, &complexSignal, 1, lnSize, FFT_FORWARD);
//    vDSP_fft_zrip(setup, &complexControl, 1, lnSize, FFT_FORWARD);
    
    // convolve signal with complex cojugate of control
    //vDSP_zvconj(&complexControl, 1, &complexControl, 1, sizeOver2);
    vDSP_zvcmul(&complexSignal, 1, &complexControl, 1, &complexSignal, 1, sizeOver2);
    
    // set first complex value to 0
    complexSignal.imagp[0] = 0.0;
    complexSignal.realp[0] = 0.0;
    
    // inverse FFT
    vDSP_fft_zrip(setup, &complexSignal, 1, lnSize, FFT_INVERSE);
    
    // back to real
    vDSP_ztoc(&complexSignal, 1, (COMPLEX *)convolution, 2, sizeOver2);
    
    // normalize
    scale = 1.f/convolution[0];
    vDSP_vsmul(convolution, 1, &scale, convolution, 1, size);

    // normalize
    vDSP_vsmul(convolution, 1, &norm, convolution, 1, size);
    
    
    // find peak
    int bestIndex = 0;
    float bestAutocorrelation = 0.0;
    for (int i=1; i<size; i++) {
        if (convolution[i]>bestAutocorrelation)
        {
            bestAutocorrelation = convolution[i];
            bestIndex = i;
        }
    }
    float phase = fmodf((((float)bestIndex)/((float)size) + 0.5), 1.0) - 0.5;
    NSLog(@"bestAutocorrelation %f phase %f scale %f", bestAutocorrelation, phase, scale);
}

@end
