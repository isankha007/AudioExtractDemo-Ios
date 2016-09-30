//
//  ViewController.m
//  VideoTrimDemo
//
//  Created by Sankhadeep Chatterjee on 09/04/16.
//  Copyright © 2016 Sankhadeep Chatterjee. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()<AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (strong, nonatomic) NSString *originalVideoPath;
@property (strong, nonatomic) NSString *tmpVideoPath;
@property (nonatomic) CGFloat startTime;
@property (nonatomic) CGFloat stopTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    
//    NSString *tempDir = NSTemporaryDirectory();
//    self.tmpVideoPath = [tempDir stringByAppendingPathComponent:@"tempMov.mov"];
    
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.originalVideoPath = [mainBundle pathForResource: @"thaiPhuketKaronBeach" ofType: @"MOV"];
    
    self.startTime=0.0;
    self.stopTime=10.0;
    
    
   
    [self convertMP4toMP3withFile:self.originalVideoPath];

}




/// stackOverFlowLink http://stackoverflow.com/questions/28643786/how-to-extract-audio-from-recorded-video-file

-(void)convertMP4toMP3withFile:(NSString*)sourcePath{

    AVMutableComposition *newAudioAsset = [AVMutableComposition composition];
    AVMutableCompositionTrack *dstCompositionTrack = [newAudioAsset addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 1 - Get media type
   
     NSURL *dstURL = [NSURL fileURLWithPath:sourcePath];
    // 3 - Handle video selection
   
    {
       AVAsset*  videoAsset = [AVURLAsset URLAssetWithURL:dstURL options:nil];
        NSArray *trackArray = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
        if(!trackArray.count){
            NSLog(@"Track returns empty array for mediatype AVMediaTypeAudio");
            return ;
        }
        
        AVAssetTrack *srcAssetTrack = [trackArray  objectAtIndex:0];
        
        //Extract time range
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero,CMTimeMake(5, 1));///because we need only 5 seconds of audio ; default is //srcAssetTrack.timeRange;
        
        NSError *err = nil;
        if(NO == [dstCompositionTrack insertTimeRange:timeRange ofTrack:srcAssetTrack atTime:kCMTimeZero error:&err]){
            NSLog(@"Failed to insert audio from the video to mutable avcomposition track");
            return ;
        }
        //Export the avcompostion track to destination path
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
        NSString *dstPath = [documentsDirectory stringByAppendingString:@"/sample_audio.caf"];
        NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
        
        
        //Remove if any file already exists
        [[NSFileManager defaultManager] removeItemAtURL:dstURL error:nil];
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:newAudioAsset presetName:AVAssetExportPresetPassthrough];
        NSLog(@"support file types= %@", [exportSession supportedFileTypes]);
        //for caf file type
        exportSession.outputFileType = AVFileTypeCoreAudioFormat;// AVFileTypeAppleM4A;//AVFileTypeCoreAudioFormat
        exportSession.outputURL = dstURL;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            AVAssetExportSessionStatus status = exportSession.status;
            
            NSLog(@"YYY %ld",(long)status);
             NSLog(@"Path %@",dstPath);
           // [self playSound:[NSURL URLWithString:dstPath]];
            [self convertToWav:dstPath];
            if(AVAssetExportSessionStatusCompleted != status){
                NSLog(@"Export status not yet completed. Error: %@", exportSession.error.description);
            }
        }];
        
        
        

 }
   
}
///http://stackoverflow.com/questions/19119422/convert-caf-file-to-wav-file-with-progress-bar-in-ios

-(void) convertToWav :(NSString*)source
{
    // set up an AVAssetReader to read from the iPod Library
    
    NSString *cafFilePath=source; //[[NSBundle mainBundle]pathForResource:@"test" ofType:@"caf"];
    
    NSURL *assetURL = [NSURL fileURLWithPath:cafFilePath];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    NSError *assetError = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset
                                                               error:&assetError]
    ;
    if (assetError) {
        NSLog (@"error: %@", assetError);
        return;
    }
    
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                              assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                              audioSettings: nil];
    if (! [assetReader canAddOutput: assetReaderOutput]) {
        NSLog (@"can't add reader output... die!");
        return;
    }
    [assetReader addOutput: assetReaderOutput];
    
    NSString *title = @"MyRec";
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex: 0];
    NSString *wavFilePath = [[docDir stringByAppendingPathComponent :title]
                             stringByAppendingPathExtension:@"wav"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:wavFilePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:wavFilePath error:nil];
    }
    NSURL *exportURL = [NSURL fileURLWithPath:wavFilePath];
    finalPath=wavFilePath;
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL
                                                          fileType:AVFileTypeWAVE
                                                             error:&assetError];
    if (assetError)
    {
        NSLog (@"error: %@", assetError);
        return;
    }
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    nil];
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                              outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput])
    {
        [assetWriter addInput:assetWriterInput];
    }
    else
    {
        NSLog (@"can't add asset writer input... die!");
        return;
    }
    
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    [assetWriter startWriting];
    [assetReader startReading];
    
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime: startTime];
    
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
                                            usingBlock: ^
     {
         
         while (assetWriterInput.readyForMoreMediaData)
         {
             CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer)
             {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 CMTime progressTime = CMSampleBufferGetPresentationTimeStamp(nextBuffer);
                 
                 CMTime sampleDuration = CMSampleBufferGetDuration(nextBuffer);
                 if (CMTIME_IS_NUMERIC(sampleDuration))
                     progressTime= CMTimeAdd(progressTime, sampleDuration);
                 float dProgress= CMTimeGetSeconds(progressTime) / CMTimeGetSeconds(songAsset.duration);
                 NSLog(@"%f",dProgress);
             }
             else
             {
                  //[self playSound:[NSURL URLWithString:finalPath]];
                 [assetWriterInput markAsFinished];
                 //              [assetWriter finishWriting];
                 [assetReader cancelReading];
                 
             }
         }
     }];
}

-(void)playSound:(NSURL*)str{
    AVAudioPlayer *_player = [[AVAudioPlayer alloc] initWithContentsOfURL:str error:NULL];
    [_player setVolume:1.0];
    _player.delegate=self;
    //_player.numberOfLoops=-1;
    [_player prepareToPlay];
    [_player play];
    NSLog(@"Playing started %@",_player);
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"Playing Finished");

}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"Playing Error");
}
/*
-(NSString*)convertMP4toMP3withFile1:(NSString*)dstPath
{
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    
    AVMutableComposition*   newAudioAsset = [AVMutableComposition composition];
    
    AVMutableCompositionTrack*  dstCompositionTrack;
    dstCompositionTrack = [newAudioAsset addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAsset*    srcAsset = [AVURLAsset URLAssetWithURL:dstURL options:nil];
    AVAssetTrack*   srcTrack = [[srcAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    self.startTime=0.0;
    self.stopTime=5.0;
    
    //CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero,CMTimeMake(5, 1)); //srcTrack.timeRange;//
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, srcAsset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.stopTime-self.startTime, srcAsset.duration.timescale);
    CMTimeRange timeRange = CMTimeRangeMake(start, duration);
   // self.exportSession.timeRange = range;
    
    
    NSError*    error;
    
    if(NO == [dstCompositionTrack insertTimeRange:timeRange ofTrack:srcTrack atTime:kCMTimeZero error:&error]) {
        NSLog(@"track insert failed: %@\n", error);
        return @"";
    }
    
    
    AVAssetExportSession*   exportSesh = [[AVAssetExportSession alloc] initWithAsset:newAudioAsset presetName:AVAssetExportPresetPassthrough];
     NSLog(@"support file types= %@", [exportSesh supportedFileTypes]);
   // exportSesh.outputFileType = AVFileTypeAppleM4A;
    exportSesh.outputFileType = AVFileTypeCoreAudioFormat;
    exportSesh.outputURL = dstURL;
    
    [[NSFileManager defaultManager] removeItemAtURL:dstURL error:nil];
    __block NSString *toPathString = @"";
    [exportSesh exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus  status = exportSesh.status;
        NSLog(@"exportAsynchronouslyWithCompletionHandler: %i\n", status);
        
        if(AVAssetExportSessionStatusFailed == status) {
            NSLog(@"FAILURE: %@\n", exportSesh.error);
        } else if(AVAssetExportSessionStatusCompleted == status) {
            NSLog(@"SUCCESS!\n");
           
            
            NSError *error;
            //append the name of the file in jpg form
            
            //check if the file exists (completely unnecessary).
            NSString *onlyPath = [dstPath stringByDeletingLastPathComponent];
           // NSString *toPathString = [NSString stringWithFormat:@"%@/testfile.m4a", onlyPath];
            toPathString = [NSString stringWithFormat:@"%@/testfile.wav", onlyPath];
            [[NSFileManager defaultManager] moveItemAtPath:dstPath toPath:toPathString error:&error];
           // [self loadFiles];
            
            AVAudioPlayer *_player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:toPathString] error:NULL];
            [_player setVolume:1.0];
            [_player play];
           // NSLog(@"Path harabo bolei ebar Path A nemechi %@",toPathString);
            
        }
    }];
    while (1) {
        if (![toPathString isEqualToString:@""]) {
            break;
        }
    }
    return toPathString;
}

*/



- (IBAction)showTrimmedVideo:(UIButton *)sender {
    
    //[self deleteTmpFile];
    [self playSound:[NSURL URLWithString:finalPath]];
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
