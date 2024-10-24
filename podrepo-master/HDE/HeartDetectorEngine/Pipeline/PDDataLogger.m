//
//  PDDataLogger.m
//  PulseDetector
//
//  Created by Andrea Canciani on 7/17/13.
//  Copyright (c) 2013 BioBeats. All rights reserved.
//

#import "PDDataLogger.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@interface PDDataLogger()
{
    NSTimeInterval boottime;
    NSDateFormatter *dateFormatter;
    NSDate *refDate;
    CMTime refTime;
}

- (NSDate *) getDateFromTimestamp: (CMTime) t;

@end

@implementation PDDataLogger

- (NSDate *) getDateFromTimestamp: (CMTime) t
{
    if (!refDate)
    {
        refDate = [NSDate date];
        refTime = t;
    }
    float secondsRef = CMTimeGetSeconds(refTime);
    float secondsT = CMTimeGetSeconds(t);
    float secondsSinceRef = secondsT - secondsRef;
    return [refDate dateByAddingTimeInterval:secondsSinceRef];
    
    
}

- (void) addSampleForTime:(CMTime) t
                  withRed:(float) r
                withGreen:(float) g
                 withBlue:(float) b
{
    NSDate *timestamp = [self getDateFromTimestamp:t];
    NSString *now  = [dateFormatter stringFromDate:timestamp];
    //NSLog(@"sample,%f,%f,%f,%f", CMTimeGetSeconds(t)+boottime, r, g, b);
    NSString *line = [NSString stringWithFormat:@"sample,%@,%f,%f,%f,%f\r\n", now, CMTimeGetSeconds(t), r, g, b ];
    [fileHandlerCsv seekToEndOfFile];
    [fileHandlerCsv writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) addAccelerationForTime:(CMTime) t
                          withX:(float) x
                          withY:(float) y
                          withZ:(float) z
{

    NSDate *timestamp = [self getDateFromTimestamp:t];
    NSString *now  = [dateFormatter stringFromDate:timestamp];
    //NSLog(@"acc,%f,%f,%f,%f", CMTimeGetSeconds(t), x, y, z);
    NSString *line = [NSString stringWithFormat:@"acc,%@,%f,%f,%f,%f\r\n", now, CMTimeGetSeconds(t), x, y, z ];
    [fileHandlerCsv seekToEndOfFile];
    [fileHandlerCsv writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)startLogging
{
    int mib[2];
    size_t size;
    struct timeval  bootTimeStruct;
    mib[0] = CTL_KERN;
    mib[1] = KERN_BOOTTIME;
    size = sizeof(bootTimeStruct);
    if (sysctl(mib, 2, &bootTimeStruct, &size, NULL, 0) != -1)
    {
        // successful call
        boottime = bootTimeStruct.tv_sec;
        NSLog(@"bootime=%f", boottime);
    } else
    {
        NSLog(@"could not retrieve device boot time");
    }
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss.SSS"];
    

    NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    NSString *path = [[[dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"]
                       stringByReplacingOccurrencesOfString:@" " withString:@"-"]
                      stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    filename = path;
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *logPath = [[NSString alloc] initWithFormat:@"%@.csv",[documentsDir stringByAppendingPathComponent:path]];
    //    NSString *dataPath = [[NSString alloc] initWithFormat:@"%@.dat",[documentsDir stringByAppendingPathComponent:path]];
    
    NSLog(@"creating log file %@", logPath);
    
    [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    fileHandlerCsv = [NSFileHandle fileHandleForWritingAtPath:logPath];
    [fileHandlerCsv seekToEndOfFile];
    [fileHandlerCsv writeData:[@"type,timestamp,1,2,3\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
}

-(void)stopLogging
{
    NSLog(@"closing log file");

    [fileHandlerCsv closeFile];
    fileHandlerCsv = nil;
    
    dateFormatter = nil;

}

- (void) addControlSignalForTime:(CMTime) t
                       withPhase:(float) p
{
    NSDate *timestamp = [self getDateFromTimestamp:t];
    NSString *now  = [dateFormatter stringFromDate:timestamp];
    NSString *line = [NSString stringWithFormat:@"phase,%@,%f,%f,%f,%f\r\n", now, CMTimeGetSeconds(t), p, p, p ];
    [fileHandlerCsv seekToEndOfFile];
    [fileHandlerCsv writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];

}


- (void) logBreathingPhase: (int) phase
{
    NSString *now  = [dateFormatter stringFromDate:[NSDate date]];
    //NSLog(@"acc,%f,%f,%f,%f", CMTimeGetSeconds(t), x, y, z);
    NSString *line = [NSString stringWithFormat:@"phase,%@,%f,%i,%i,%i\r\n", now, 0.0, phase, phase, phase ];
    [fileHandlerCsv seekToEndOfFile];
    [fileHandlerCsv writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    
}


@end
