//
//  ZZWaveView.m
//  ZZSpeechRecognizerDemo
//
//  Created by zhouzheng on 2018/1/25.
//  Copyright © 2018年 zhouzheng. All rights reserved.
//

#import "ZZWaveView.h"

@interface ZZWaveView()

@property (nonatomic, strong) CADisplayLink *wavesDisplayLink;
@property (nonatomic, strong) CAShapeLayer *waveLayer;

@end

@implementation ZZWaveView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.masksToBounds = YES;
        [self defaultInit];
        [self createWave];
    }
    return self;
}

- (void)defaultInit {
    self.waveA = 12;
    self.waveW = 0.5/10.0;
    self.waveX = 0;
    self.waveC = self.frame.size.height/2;
    self.waveSpeed = 0.5/M_PI;
    self.waveWidth = self.frame.size.width;
    self.waveColor = [UIColor whiteColor];
    self.waveOpacity = 1.0;
}

- (void)setWaveA:(CGFloat)waveA {
    _waveA = waveA;
    [self createWave];
}

- (void)setWaveW:(CGFloat)waveW {
    _waveW = waveW;
    [self createWave];
}

- (void)setWaveX:(CGFloat)waveX {
    _waveX = waveX;
    [self createWave];
}

- (void)setWaveC:(CGFloat)waveC {
    _waveC = waveC;
    [self createWave];
}

- (void)setWaveSpeed:(CGFloat)waveSpeed {
    _waveSpeed = waveSpeed;
    [self createWave];
}

- (void)setWaveWidth:(CGFloat)waveWidth {
    _waveWidth = waveWidth;
    [self createWave];
}

- (void)setWaveColor:(UIColor *)waveColor {
    _waveColor = waveColor;
    [self createWave];
}

- (void)setWaveOpacity:(CGFloat)waveOpacity {
    _waveOpacity = waveOpacity;
    [self createWave];
}

- (void)createWave {
    if (self.waveLayer == nil) {
        //初始化
        self.waveLayer = [CAShapeLayer layer];
        //设置闭环的颜色
        self.waveLayer.fillColor = [UIColor clearColor].CGColor;
        //设置边缘线的宽度
        self.waveLayer.lineWidth = 3;
        self.waveLayer.strokeStart = 0.0;
        self.waveLayer.strokeEnd = 1.0;
        
        [self.layer addSublayer:self.waveLayer];
    }
    //设置边缘线的颜色
    self.waveLayer.strokeColor = self.waveColor.CGColor;
    self.waveLayer.opacity = self.waveOpacity;
    
    //启动定时器
    if (self.wavesDisplayLink == nil) {
        self.wavesDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(getCurrentWave:)];
        [self.wavesDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)getCurrentWave:(CADisplayLink *)displayLink {
    
    self.waveX += self.waveSpeed;
    [self setCurrentWaveLayerPath];
}

-(void)setCurrentWaveLayerPath{
    
    //创建一个路径
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat y = self.waveC;
    //将点移动到 x=0,y=waveC的位置
    CGPathMoveToPoint(path, nil, 0, y);
    
    for (NSInteger i=0.0f; i<=self.waveWidth; i++) {
        //正弦函数波浪公式
        y = self.waveA * sin(self.waveW * i + self.waveX) + self.waveC;
        //将点连成线
        CGPathAddLineToPoint(path, nil, i, y);
    }
    
    CGPathAddLineToPoint(path, nil, self.waveWidth, 0);
    CGPathAddLineToPoint(path, nil, 0, 0);
    
    CGPathCloseSubpath(path);
    self.waveLayer.path = path;
    
    //使用layer 而没用CurrentContext
    CGPathRelease(path);
    
}

- (void)dealloc {
    [self.wavesDisplayLink invalidate];
    self.wavesDisplayLink = nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
