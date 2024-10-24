//
//  HRVHelper.m
//  BioBeatsBreathe
//
//  Created by Davide Morelli on 29/09/15.
//  Copyright © 2015 BioBeats. All rights reserved.
//



#import "HRVFeatureExtractor.h"
#import <Accelerate/Accelerate.h>
#import "StreamAnalyzer.h"
#import "MakeUniformTime.h"

static inline float stddev(float* values,size_t count, float avg ){
    // SDNN
    float mean;
    
    vDSP_measqv(values, 1, &mean, count);
    return sqrt(mean - avg * avg);
}

#define MIN_BEATS_FOR_FREQUENCY_FEATURES 30

//#define DEBUG_FFT_PRINTS 1

@interface HRVFeatureExtractor()<StreamAnalyzer>
{
    float *resampledRR;
    int currResampledRRIndex;
    int resampledRR_count;
}
@end

@implementation HRVFeatureExtractor

- (id)initWithNNPeriods:(NSArray *)periods andPPGSamples:(NSArray *)samples atSampleRate:(NSNumber *)sr
{
    self = [super init];
    if (self) {
        _periods = periods;
        _PPGSamples = samples;
        _samplerate = sr;
    }
    return self;
}

- (id)initWithJSONRepresentation:(NSString *)json
{
    self = [super init];
    if (self) {
        NSError *jsonError;
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        if (data == nil)
        {
            NSLog(@"initWithJSONRepresentation : json is empty");
            self.extractedTimeDomainFeatures = NO;
            self.extractedFrequencyDomainFeatures = NO;
        } else
        {
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&jsonError];
            if (jsonError)
            {
                NSLog(@"error decoding JSON");
                NSLog(@"JSON: %@", json);
                NSLog(@"error: %@", jsonError);
                self.extractedTimeDomainFeatures = NO;
                self.extractedFrequencyDomainFeatures = NO;
            } else
            {
                _periods = [jsonDict objectForKey:FIELD_NAME_PERIODS];
                _averageHR = [jsonDict objectForKey:FIELD_NAME_AVERAGE_HR];
                _averageNN = [jsonDict objectForKey:FIELD_NAME_AVERAGE_NN];
                _pNN50 = [jsonDict objectForKey:FIELD_NAME_pNN50];
                _SVI = [jsonDict objectForKey:FIELD_NAME_SVI];
                _SDNN = [jsonDict objectForKey:FIELD_NAME_SDNN];
                _RMSSD = [jsonDict objectForKey:FIELD_NAME_RMSSD];
                _LF = [jsonDict objectForKey:FIELD_NAME_LF];
                _HF = [jsonDict objectForKey:FIELD_NAME_HF];
                _SD1 = [jsonDict objectForKey:FIELD_NAME_SD1];
                _SD2 = [jsonDict objectForKey:FIELD_NAME_SD2];
                _SDSD = [jsonDict objectForKey:FIELD_NAME_SDSD];
                if ([jsonDict objectForKey:FIELD_NAME_ENTROPY])
                {
                    _ApEn = [jsonDict objectForKey:FIELD_NAME_ENTROPY];
                }
                if ([jsonDict objectForKey:FIELD_NAME_PPG_SAMPLES])
                {
                    _PPGSamples = [jsonDict objectForKey:FIELD_NAME_PPG_SAMPLES];
                }
                if ([jsonDict objectForKey:FIELD_NAME_PPG_SAMPLERATE])
                {
                    _samplerate = [jsonDict objectForKey:FIELD_NAME_PPG_SAMPLERATE];
                }
                self.extractedTimeDomainFeatures = YES;
                self.extractedFrequencyDomainFeatures = YES;

            }
        }


    }
    return self;
}

-(BOOL)appendFeature:(NSNumber*)feature toJSONRepresentation:(NSMutableString*)json withID:(NSString*)featureID addingFinalComma:(BOOL)addFinalComma{
    
    float value = [feature floatValue];
    
    //check if the feature is different from NaN and INF
    if(isfinite(value)){
        [json appendFormat:@"\"%@\":%f", featureID, value];
        if(addFinalComma){
            [json appendFormat:@","];
        }
        return YES;
    }
    
    return NO;
}

-(BOOL)isNumberArrayValid:(NSArray*)array{
    BOOL isValid = YES;
    for (NSNumber* num in array) {
        isValid = isValid && isfinite([num floatValue]);
    }
    return isValid;
}

- (NSString *)createJSONRepresentation
{
    NSMutableString *json = [[NSMutableString alloc] init];
    [json appendString:@"{"];
    
    // the simple fields
    [self appendFeature:self.averageNN toJSONRepresentation:json withID:FIELD_NAME_AVERAGE_NN addingFinalComma:YES];
    [self appendFeature:self.averageHR toJSONRepresentation:json withID:FIELD_NAME_AVERAGE_HR addingFinalComma:YES];
    [self appendFeature:self.pNN50 toJSONRepresentation:json withID:FIELD_NAME_pNN50 addingFinalComma:YES];
    [self appendFeature:self.SDNN toJSONRepresentation:json withID:FIELD_NAME_SDNN addingFinalComma:YES];
    [self appendFeature:self.RMSSD toJSONRepresentation:json withID:FIELD_NAME_RMSSD addingFinalComma:YES];
    [self appendFeature:self.SDSD toJSONRepresentation:json withID:FIELD_NAME_SDSD addingFinalComma:YES];
    [self appendFeature:self.SD1 toJSONRepresentation:json withID:FIELD_NAME_SD1 addingFinalComma:YES];
    [self appendFeature:self.SD2 toJSONRepresentation:json withID:FIELD_NAME_SD2 addingFinalComma:YES];
    [self appendFeature:self.ApEn toJSONRepresentation:json withID:FIELD_NAME_ENTROPY addingFinalComma:YES];
    [self appendFeature:self.SVI toJSONRepresentation:json withID:FIELD_NAME_SVI addingFinalComma:YES];
    [self appendFeature:self.LF toJSONRepresentation:json withID:FIELD_NAME_LF addingFinalComma:YES];
    [self appendFeature:self.HF toJSONRepresentation:json withID:FIELD_NAME_HF addingFinalComma:YES];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_AVERAGE_NN, [self.averageNN floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_AVERAGE_HR, [self.averageHR floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_pNN50, [self.pNN50 floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_SDNN, [self.SDNN floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_RMSSD, [self.RMSSD floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_SDSD, [self.SDSD floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_SD1, [self.SD1 floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_SD2, [self.SD2 floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_ENTROPY, [self.ApEn floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_SVI, [self.SVI floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_LF, [self.LF floatValue]];
    //[json appendFormat:@"\"%@\":%f,", FIELD_NAME_HF, [self.HF floatValue]];
    
    // periods
    [json appendFormat:@"\"%@\":[", FIELD_NAME_PERIODS ];
    
    //check if the periods array is valid, otherwise leave it empty
    if([self isNumberArrayValid:self.periods]){
        for (NSNumber *n in self.periods) {
            [json appendFormat:@"%.4f,", [n floatValue]];
        }
        
        if ([self.periods count] > 0)
            [json deleteCharactersInRange:NSMakeRange([json length] - 1, 1)]; // delete last ,
    }
    [json appendString:@"],"];
    
    // PPG samplearate
    [self appendFeature:self.samplerate toJSONRepresentation:json withID:FIELD_NAME_PPG_SAMPLERATE addingFinalComma:NO];

    if (self.includePPG)
    {
        [json appendString:@","];
        // PPG samples
        [json appendFormat:@"\"%@\":[", FIELD_NAME_PPG_SAMPLES ];
        
        //check if the PPGSamples array is valid, otherwise leave it empty
        if([self isNumberArrayValid:self.PPGSamples]){
            for (NSNumber *n in self.PPGSamples) {
                [json appendFormat:@"%.4f,", [n floatValue]];
            }
            if ([self.PPGSamples count] > 0)
                [json deleteCharactersInRange:NSMakeRange([json length] - 1, 1)]; // delete last ,
        }
        [json appendString:@"]"];
    }
    [json appendString:@"}"];
    return json ;
}

- (BOOL)extractFeatures
{

    self.extractedTimeDomainFeatures = NO;
    self.extractedFrequencyDomainFeatures = NO;
    // not enough samples to do anything
    self.averageNN = nil;
    self.averageHR = nil;
    self.pNN50 = nil;
    self.SVI = nil;
    self.RMSSD = nil;
    
    if (self.periods == nil || [self.periods count] < 1)
        return NO;
    // prepare the array of NN values
    NSUInteger n_beats = [self.periods count];
    float NN[n_beats];
    float NN_tmp[n_beats-1];
    float NN_tmp2[n_beats-1];
    float NN_tmp3[n_beats];
    for (NSUInteger i = 0; i<n_beats; i++) {
        NN[i] = [[self.periods objectAtIndex:i] floatValue];
    }
    // array of HR values
    float oneSecond = 60.0;
    float HR[n_beats];
    vDSP_svdiv(&oneSecond, NN, 1, HR, 1, n_beats);
    
    // calculate averages
    float mean = 0.0;
    vDSP_meanv(NN, 1, &mean, n_beats);

    // calculate averages
    float meanHR = 0.0;
    vDSP_meanv(HR, 1, &meanHR, n_beats);

    self.averageNN = [NSNumber numberWithFloat:mean];
    self.averageHR = [NSNumber numberWithFloat:meanHR];
    
    // the other features need at least 2 beats
    if (n_beats < 2)
        return NO;

    // SDNN
    self.SDNN = [NSNumber numberWithFloat:stddev(NN, n_beats, mean)];
    
    // pNN50
    int count = 0;
    for (NSUInteger i = 1; i<n_beats; i++) {
        if (fabs(NN[i] - NN[i-1]) > 0.05)
            count++;
    }
    self.pNN50 = [NSNumber numberWithFloat:((float)count)/((float)(n_beats-1))];
    
    // RMSSD
    vDSP_vsub(NN+1, 1, NN, 1, NN_tmp, 1, n_beats - 1); // NN_tmp = differences
    vDSP_vsq(NN_tmp, 1, NN_tmp2, 1, n_beats - 1); // NN_tmp2 = differences squared
    vDSP_meanv(NN_tmp2, 1, &mean, n_beats - 1); // mean = average of differences
    self.RMSSD = [NSNumber numberWithFloat:sqrtf(mean)];
    
    // SDSD
    vDSP_meanv(NN_tmp, 1, &mean, n_beats - 1); // mean = average of differences
    float sd = stddev(NN_tmp, n_beats - 1, mean);
    self.SDSD = [NSNumber numberWithFloat:sd];
    
    // see http://www.physionet.org/events/hrv-2006/yang.pdf
    float sd1 = sqrt(0.5 * sd * sd);
    float sd2 = sqrt(2.0 * [self.SDNN floatValue] * [self.SDNN floatValue] - 0.5 * sd * sd);
    self.SD1 = [NSNumber numberWithFloat:sd1];
    self.SD2 = [NSNumber numberWithFloat:sd2];
    
    float max;
    vDSP_maxv(NN, 1, &max, n_beats);
    float min;
    vDSP_minv(NN, 1, &min, n_beats);
    self.range = [NSNumber numberWithFloat:max - min];
    
    // Approximate Entropy
    float ApEn = [self ApEnUtilCalcPhiForArray:self.periods length:2 andTolerance:([self.SDNN floatValue] * 0.2)] -
    [self ApEnUtilCalcPhiForArray:self.periods length:3 andTolerance:([self.SDNN floatValue] * 0.2)];
    self.ApEn = [NSNumber numberWithFloat:ApEn];
    
    
    // frequency domain features
    if (n_beats < MIN_BEATS_FOR_FREQUENCY_FEATURES)
        return NO;
    
    self.extractedTimeDomainFeatures = YES;
    
    // resample NN to make it evenly spaced
    float currentTime = 0.0;
    NSUInteger currentNNSample = 0;
    float currentBeatStarted = 0.0;
    float currentBeatEnds = NN[currentNNSample];
    float totalDuration = 0.0;
    vDSP_sve(NN, 1, &totalDuration, n_beats);
    // the last period is the arriving point, it should be removed
    totalDuration = totalDuration - NN[n_beats-1];
    // how many samples the resampled NN have?
    // we resample at 4 Hz
    float samplingRate = 4.0;
    int numberOfSamples = ceilf(totalDuration * samplingRate);
    // this array will contain the NN points resampled at samplingRate Hz
    float NN_resampled[numberOfSamples];
    float timeIncrement = 1.0 / samplingRate;
    // this is a temporary vector used to run vDSP_vlint
    float tmp_resampling[numberOfSamples];
    for (int i = 0; i<numberOfSamples; i++, currentTime += timeIncrement) {
        if (currentTime > currentBeatEnds)
        {
            // move to the next beat
            currentBeatStarted = currentBeatEnds;
            currentNNSample++;
            currentBeatEnds = currentBeatStarted + NN[currentNNSample];
        }
        // calculate the weigth
        // create a float with:
        // integral part = index of the NN
        // decimal part = weigth
        float decimalPart = (currentTime - currentBeatStarted)/NN[currentNNSample];
        float integralPart = (float) currentNNSample;
        tmp_resampling[i] = decimalPart + integralPart;
    }
    // this code checks the requisites for calling vDSP_vlint
    for (int i = 0; i<numberOfSamples; i++) {
        if (floorf(tmp_resampling[i])<0 || floorf(tmp_resampling[i])>(n_beats-2))
        {
            return NO;
        }
    }
    vDSP_vlint(NN, tmp_resampling, 1, NN_resampled, 1, numberOfSamples, n_beats);
    // remove mean
//    vDSP_meanv(NN_resampled, 1, &mean, numberOfSamples);
//    vDSP_vsadd(NN_resampled, 1, &mean, NN_resampled, 1, numberOfSamples);
//    // apply hanning window
//    float hann[numberOfSamples];
//    vDSP_hann_window(hann, numberOfSamples, vDSP_HANN_NORM);
//    vDSP_vmul(NN_resampled, 1, hann, 1, NN_resampled, 1, numberOfSamples);
    
//    // DEBUG
//    NSLog(@"resampled NN points:");
//    for (int i = 0; i<numberOfSamples; i++) {
//        NSLog(@"%d: %f", i, NN_resampled[i]);
//    }

#ifdef DEBUG_FFT_PRINTS
    // print the resampled NN serie
    NSMutableString *json = [[NSMutableString alloc] init];
    NSMutableString *jsonT = [[NSMutableString alloc] init];
    [jsonT appendFormat:@"0.0"];
    [json appendFormat:@"%.4f", NN_resampled[0]];
    for (int i = 1; i < numberOfSamples; i++) {
        [jsonT appendFormat:@",%.4f", ((float)i)/4.0];
        [json appendFormat:@",%.4f", NN_resampled[i]];
    }
    NSLog(@"RR.resampled.timestamps = c(%@)", jsonT);
    NSLog(@"RR.resampled.values = c(%@)", json);
#endif
    
    // https://github.com/hoddez/FFTAccelerate/blob/master/FFTAccelerate/FFTAccelerate.cpp
    int numSamples = exp2f(floor(log2f(numberOfSamples))); // enforce power of 2
    float *samples = NN_resampled;
    FFTSetup fftSetup;
    COMPLEX_SPLIT A;
    vDSP_Length log2n = log2f(numSamples);
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    int nOver2 = numSamples/2;
    A.realp = (float *) malloc(nOver2*sizeof(float));
    A.imagp = (float *) malloc(nOver2*sizeof(float));
    float amp[numSamples];
    
    //Convert float array of reals samples to COMPLEX_SPLIT array A
    vDSP_ctoz((COMPLEX*)samples,2,&A,1,nOver2);
    
    //Perform FFT using fftSetup and A
    //Results are returned in A
    vDSP_fft_zrip(fftSetup, &A, 1, log2n, FFT_FORWARD);
    
    //Convert COMPLEX_SPLIT A result to float array to be returned
    
    vDSP_zvmags(&A, 1, amp, 1, nOver2); // get amplitude squared
    vvsqrtf(amp, amp, &nOver2);         // get amplitude
    amp[0] = amp[0]/2.;
    
    float fNumSamples = 2 * numSamples;
    vDSP_vsdiv(amp, 1, &fNumSamples, amp, 1, numSamples);   // /numSamples
    
    
    float VLF = 0.0;
    float LF = 0.0;
    float HF = 0.0;

    NSMutableArray *spectFreqsFrom = [[NSMutableArray alloc] init];
    NSMutableArray *spectFreqsTo = [[NSMutableArray alloc] init];
    NSMutableArray *spectPower = [[NSMutableArray alloc] init];

#ifdef DEBUG_FFT_PRINTS
    json = [[NSMutableString alloc] init];
    [json appendFormat:@"%.4f", amp[0]];
    for (int i = 1; i < nOver2; i++) {
        [json appendFormat:@",%.4f", amp[i]];
    }
    NSLog(@"spectrum = c(%@)", json);
    NSLog(@"amplitude:");
#endif
    float binSize = ((float) samplingRate) / ((float)numSamples);

    for (int i = 1; i < nOver2; i++) {
        float freqFrom = ((float) i) * binSize;
        float freqTo = ((float) i+1) * binSize;
#ifdef DEBUG_FFT_PRINTS
        NSLog(@"%.4f %.4f", freqFrom, amp[i]);
#endif

        [spectFreqsFrom addObject:  [NSNumber numberWithFloat:freqFrom]];
        [spectFreqsTo addObject:  [NSNumber numberWithFloat:freqTo]];
        [spectPower addObject:[NSNumber numberWithFloat:amp[i]]];
        
        if (freqFrom > 0.003 && freqTo < 0.04)
            VLF += amp[i];
        if (freqFrom > 0.04 && freqTo < 0.15)
            LF += amp[i];
        if (freqFrom > 0.15 && freqTo < 0.4)
            HF += amp[i];
//        NSLog(@"%d: (%f to %f) : %f", i, freqFrom, freqTo, amp[i]);
    }
    self.VLF = [NSNumber numberWithFloat:VLF];
    self.LF = [NSNumber numberWithFloat:LF];
    self.HF = [NSNumber numberWithFloat:HF];
    self.SVI = [NSNumber numberWithFloat:LF/HF];
   
    self.spectrumFrequencyFrom = spectFreqsFrom;
    self.spectrumFrequencyTo = spectFreqsTo;
    self.spectrumPower = spectPower;
    
    free(A.realp);
    free(A.imagp);
    vDSP_destroy_fftsetup(fftSetup);
    
    self.extractedFrequencyDomainFeatures = YES;
    return YES;
}

- (float) ApEnUtilCalcDBetweenArray: (NSArray *) array1
                           andArray: (NSArray *) array2
{
    if ([array1 count] != [array2 count])
    {
        NSLog(@"arrays have different length");
        abort();
    }
    float dist = 0.0;
    for (int i = 0; i < [array1 count]; i++) {
        float thisDist = fabsf([array1[i] floatValue] - [array2[i] floatValue]);
        if (thisDist > dist)
            dist = thisDist;
    }
    return dist;
}

- (float) ApEnUtilCalcCForArray: (NSArray *) array
                      withIndex: (int) i
                         length: (int) m
                   andTolerance: (float) r
{
    NSArray *Xi = [array subarrayWithRange:NSMakeRange(i, m)];
    int count = 0;
    for (int j = 0; j<[array count] - m + 1; j++) {
        NSArray *Xj = [array subarrayWithRange:NSMakeRange(j, m)];
        float dist = [self ApEnUtilCalcDBetweenArray:Xi andArray:Xj];
        if (dist < r)
            count++;
    }
    return ((float)count)/((float)([array count] - m + 1));
}

- (float) ApEnUtilCalcPhiForArray: (NSArray *) array
                         length: (int) m
                   andTolerance: (float) r
{
    float sum = 0.0;
    for (int i = 0; i<[array count] - m + 1; i++) {
        float c = [self ApEnUtilCalcCForArray:array withIndex:i length:m andTolerance:r];
        sum += logf(c); 
    }
    return sum / ((float)([array count] - m + 1));
}

// find the overall breathing exercise execution quality
// given an array of RR intervals and a breathing frequency
- (float) breathingQualityAtBreathingFrequency: (float) BreathingHz
{
    // in case of invalid periods, return 0
    if (self.periods == nil || [self.periods isEqual:[NSNull null]] || [self.periods count] == 0)
        return 0.0;
    
    // step 1: resample RR intervals
    NSMutableArray *cumulativeRR = [[NSMutableArray alloc] init];
    [cumulativeRR addObject:[NSNumber numberWithFloat:0.0]];
    float sum = 0.0;
    // discard the last one
    // this array contains the moments when each RR interval happens
    for (int i = 0; i<[self.periods count] - 1; i++) {
        sum += [self.periods[i] floatValue];
        [cumulativeRR addObject:[NSNumber numberWithFloat:sum]];
    }
    // if it's too short, quality can't be any good
    if (sum < 1.0)
        return 0.0;
    // now cumulativeRR[i] tells us when the RR[i] beat happens
    // now use MakeUniform to do the job
    MakeUniformTime *resampler = [[MakeUniformTime alloc] initWithSamplerate:10.0];
    resampler.delegate = self;
    // prepare the array that will contain the resampled data
    resampledRR_count = sum*10;
    resampledRR = (float *) calloc(resampledRR_count, sizeof(float));
    for (int i = 0; i<[self.periods count]; i++) {
        CMTime when = CMTimeMake([cumulativeRR[i] floatValue] * 1000.0, 1000);
        [resampler addSampleWithTime:when value:[self.periods[i] floatValue] andStreamID:1];
    }
    // resampledRR now contains the resampled tachogram
//    for (int i = 0; i<resampledRR_count; i++) {
//        NSLog(@"resampledRR[%i]=%f", i, resampledRR[i]);
//    }

    // step 2: generate a sinusoid at 10 Hz, with period 1/BreathingHz
    // the control signal needs to be londer than the signal (see vDSP_conv)
    float *control = (float *) calloc(resampledRR_count+100, sizeof(float));
    float period = 1.0 / BreathingHz;
    float time_increment = 0.1;
    for (int i = 0; i<resampledRR_count+100; i++) {
        control[i] = sinf(M_PI * 2.0 * ((float)i) * time_increment / period);
//        NSLog(@"control[%i]=%f", i, control[i]);
    }
    
    // TEST print resampled
//    for(int i =0;i<resampledRR_count;i++)
//    {
//        NSLog(@", %f, %f, %f", i*time_increment, resampledRR[i], control[i]);
//    }
    
//    // step 3: z normalize control and resampled intervals
//    float mean, sd;
//    vDSP_normalize(resampledRR, 1, resampledRR, 1, &mean, &sd, resampledRR_count);
//    vDSP_normalize(control, 1, control, 1, &mean, &sd, resampledRR_count+100);

    // step 4: run cross correlation
    // see http://stackoverflow.com/questions/10917951/perform-autocorrelation-with-vdsp-conv-from-apple-accelerate-framework
    // the maximum offset is 1 period = 100 samples (10 seconds at 10 Hz)
    float *xcorrelation = (float *) calloc(100, sizeof(float));
    //vDSP_conv(control, 1, resampledRR, 1, xcorrelation, 1, 100, resampledRR_count);
    
    float meanResampledRR;
    vDSP_meanv(resampledRR, 1, &meanResampledRR, resampledRR_count);
    float meanControl;
    vDSP_meanv(control, 1, &meanControl, resampledRR_count+100);
    
    float sdResampledRR=0.0, sdControl=0.0;
    // discard the last second of resampled RR    
    for (int i=0; i<resampledRR_count-10; i++) {
        sdResampledRR += (resampledRR[i] - meanResampledRR) * (resampledRR[i] - meanResampledRR);
        sdControl += (control[i] - meanControl) * (control[i] - meanControl);
    }
    sdResampledRR /= resampledRR_count;
    sdControl /= resampledRR_count;
    sdResampledRR = sqrtf(sdResampledRR);
    sdControl = sqrtf(sdControl);
    
    for (int lag=0; lag<100; lag++) {
        xcorrelation[lag] = 0.0;
        // discard the last second of resampled RR
        for (int j = 0; j<resampledRR_count-10; j++) {
            xcorrelation[lag]+=(resampledRR[j]-meanResampledRR) * (control[j+lag] - meanControl);
        }
        xcorrelation[lag] /= (resampledRR_count);
        xcorrelation[lag] /= (sdResampledRR*sdControl);
    }
    
    // step 5: quality = max value in cross correlation output
//    for (int i = 0; i<100; i++) {
//        NSLog(@"xcorrelation[%i]=%f", i, xcorrelation[i]);
//    }
    float max;
    vDSP_maxv(xcorrelation, 1, &max, 100);
    
    // free resources
    free(resampledRR);
    free(control);
    free(xcorrelation);
    return max;
}

- (void)addSampleWithTime:(CMTime)t value:(float)v andStreamID:(int)ID
{
    if (currResampledRRIndex < resampledRR_count)
        resampledRR[currResampledRRIndex++] = v;
}

@end
