//
//  ViewController.m
//  ZZSpeechRecognizerDemo
//
//  Created by zhouzheng on 2018/1/10.
//  Copyright © 2018年 zhouzheng. All rights reserved.
//

#import "ViewController.h"
#import "ZZWaveView.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import "ZZSpeechManager.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface ViewController ()<ZZSpeechManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
- (IBAction)recordButtonClick:(UIButton *)sender;

@property (nonatomic, strong) UIView *waveView;
@property (nonatomic, strong) ZZWaveView *firstWaveView;
@property (nonatomic, strong) ZZWaveView *secondWaveView;
@property (nonatomic, strong) ZZWaveView *thirdWaveView;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    __weak typeof(self)weakself = self;
    [[ZZSpeechManager shareManager] SFSpeechRecognizerCanAllow:^(BOOL isAllow, NSString *message) {
        weakself.recordButton.enabled = isAllow;
        [weakself.recordButton setTitle:message forState:UIControlStateNormal];
    }];
    [ZZSpeechManager shareManager].delegate = self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _waveView = [[UIView alloc] initWithFrame:CGRectMake(60, 125, ScreenWidth-120, 180)];
    _waveView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_waveView];
    
    _firstWaveView = [[ZZWaveView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth-120, 180)];
    _firstWaveView.waveA = 10;
    _firstWaveView.waveX = 0;
    _firstWaveView.waveSpeed = 0.6/M_PI;
    _firstWaveView.waveOpacity = 0.6;
    [_waveView addSubview:_firstWaveView];
    
    _secondWaveView = [[ZZWaveView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth-120, 180)];
    _secondWaveView.waveA = 6;
    _secondWaveView.waveX = 15;
    _secondWaveView.waveSpeed = 0.3/M_PI;
    _secondWaveView.waveOpacity = 0.5;
    [_waveView addSubview:_secondWaveView];
    
    _thirdWaveView = [[ZZWaveView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth-120, 180)];
    _thirdWaveView.waveA = 4;
    _thirdWaveView.waveX = 30;
    _thirdWaveView.waveSpeed = 0.8/M_PI;
    _thirdWaveView.waveOpacity = 0.4;
    [_waveView addSubview:_thirdWaveView];
    
    _waveView.hidden = YES;
}

- (IBAction)recordButtonClick:(UIButton *)sender {
   
    if ([ZZSpeechManager shareManager].audioEngine.isRunning) {
        [[ZZSpeechManager shareManager] stop];
        _firstWaveView.waveA = 10;
        _secondWaveView.waveA = 6;
        _thirdWaveView.waveA = 4;
        _waveView.hidden = YES;
        self.recordButton.enabled = NO;
        [self.recordButton setTitle:@"正在停止" forState:UIControlStateDisabled];
        
    }else {
        [[ZZSpeechManager shareManager] start];
        _waveView.hidden = NO;
        [self.recordButton setTitle:@"停止录音" forState:UIControlStateNormal];
    }
}

#pragma mark - >>>>>>>>> ZZSpeechManagerDelegate <<<<<<<<<

//实时音量
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager volume:(CGFloat)volume {
    CGFloat changeWaveA = (volume+160);
    _firstWaveView.waveA = 0.3 * changeWaveA + volume * 0.5;
    _secondWaveView.waveA = 0.2 * changeWaveA + volume * 0.4;
    _thirdWaveView.waveA = 0.15 * changeWaveA + volume * 0.3;
}

//实时结果
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager realTimeResult:(NSString *)realTimeResult {
    
}

//最终结果
- (void)zzSpeechManager:(ZZSpeechManager *)zzSpeechManager finalResult:(NSString *)finalResult {
    
    self.recordButton.enabled = YES;
    [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    self.resultLabel.text = finalResult;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
