//
//  ViewController.h
//  VideoTrimDemo
//
//  Created by Sankhadeep Chatterjee on 09/04/16.
//  Copyright © 2016 Sankhadeep Chatterjee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController{
    NSString *finalPath;
}

-(void)playSound:(NSURL*)str;


@end

