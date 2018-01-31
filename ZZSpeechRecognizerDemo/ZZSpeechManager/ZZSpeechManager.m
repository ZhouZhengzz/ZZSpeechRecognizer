//
//  ZZSpeechManager.m
//  ZZSpeechRecognizerDemo
//
//  Created by zhouzheng on 2018/1/29.
//  Copyright © 2018年 zhouzheng. All rights reserved.
//

#import "ZZSpeechManager.h"
#import <Speech/Speech.h>


typedef void(^CanAllowBlock)(BOOL isAllow, NSString *message);

@interface ZZSpeechManager()<SFSpeechRecognizerDelegate>

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

@property (nonatomic, strong) AVAudioRecorder *recorder;//录音
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, copy) CanAllowBlock canAllowBlock;

@end

@implementation ZZSpeechManager

+ (instancetype)shareManager {
    static ZZSpeechManager *speechManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        speechManager = [[ZZSpeechManager alloc] init];
    });
    return speechManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self steupRecorder];
    }
    return self;
}

- (void)SFSpeechRecognizerCanAllow:(void (^)(BOOL, NSString *))canAllowBlock {
    
    _canAllowBlock = canAllowBlock;
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined: {
                    if (_canAllowBlock) {
                        _canAllowBlock(NO, @"语音识别未授权");
                    }
                }
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied: {
                    if (_canAllowBlock) {
                        _canAllowBlock(NO, @"用户未授权使用语音识别");
                    }
                }
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted: {
                    if (_canAllowBlock) {
                        _canAllowBlock(NO, @"语音识别在这台设备上受到限制");
                    }
                }
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized: {
                    if (_canAllowBlock) {
                        _canAllowBlock(YES, @"开始录音");
                    }
                }
                    break;
                default:
                    break;
            }
        });
    }];
}


- (void)steupRecorder {
    
    // 1. 音频会话
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    // 参数设置
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 14400.0], AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatAppleIMA4], AVFormatIDKey,
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                                    nil];
    
    NSString *recordPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"record.caf"];
    NSURL *recordURL = [NSURL fileURLWithPath:recordPath];
    _recorder = [[AVAudioRecorder alloc] initWithURL:recordURL settings:recordSettings error:NULL];
    _recorder.meteringEnabled = YES;
}

#pragma mark - lazyload
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        //要为语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

- (void)start {
    [self startRecording];
    [_recorder record];
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    }
}

- (void)stop {
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        if (_recognitionRequest) {
            [_recognitionRequest endAudio];
        }
    }
}

- (void)updateTimer {
    
    [_recorder updateMeters];
    // 获得0声道的音量，完全没有声音-160.0，0是最大音量
    CGFloat power = [_recorder peakPowerForChannel:0];
    NSLog(@"%.2f", power);
    if ([self.delegate respondsToSelector:@selector(zzSpeechManager:volume:)]) {
        [self.delegate zzSpeechManager:self volume:power];
    }
    
}

- (void)startRecording{
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        
        NSLog(@"%@",result.bestTranscription.formattedString);
        
        BOOL isFinal = NO;
        if (result) {
            isFinal = result.isFinal;
            if ([weakSelf.delegate respondsToSelector:@selector(zzSpeechManager:realTimeResult:)]) {
                [weakSelf.delegate zzSpeechManager:weakSelf realTimeResult:result.bestTranscription.formattedString];
            }
            
        }
        if (error || isFinal) {
            
            [_timer invalidate];
            _timer = nil;
            //删除录音文件
            [_recorder deleteRecording];
            
            [weakSelf.audioEngine stop];
            [inputNode removeTapOnBus:0];
            weakSelf.recognitionTask = nil;
            weakSelf.recognitionRequest = nil;
            
            if ([weakSelf.delegate respondsToSelector:@selector(zzSpeechManager:finalResult:)]) {
                [weakSelf.delegate zzSpeechManager:weakSelf finalResult:result.bestTranscription.formattedString];
            }
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        
        if (weakSelf.recognitionRequest) {
            [weakSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
}


@end
