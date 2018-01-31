//
//  ZZSpeechManager.h
//  ZZSpeechRecognizerDemo
//
//  Created by zhouzheng on 2018/1/29.
//  Copyright © 2018年 zhouzheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class ZZSpeechManager;
@protocol ZZSpeechManagerDelegate <NSObject>

//录音0声道音量，-160~0
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager volume:(CGFloat)volume;
//实时结果
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager realTimeResult:(NSString *)realTimeResult;
//最终结果
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager finalResult:(NSString *)finalResult;

@end

@interface ZZSpeechManager : NSObject

@property (nonatomic, weak) id<ZZSpeechManagerDelegate> delegate;
@property (nonatomic, strong) AVAudioEngine *audioEngine;

+ (instancetype)shareManager;

//是否允许语音识别
- (void)SFSpeechRecognizerCanAllow:(void(^)(BOOL isAllow, NSString *message))canAllowBlock;
- (void)start;
- (void)stop;

@end
