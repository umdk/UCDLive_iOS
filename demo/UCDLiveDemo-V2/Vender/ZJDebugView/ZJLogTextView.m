//
//  ZJLogTextView.m
//  RunTime
//
//  Created by foscom on 16/7/12.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import "ZJLogTextView.h"
#import "GetLogFile.h"
#import "AppDelegate.h"
#import "XTPopView.h"
#import "InfoView.h"

#define BUTTON_HIGHT 30
@interface ZJLogTextView ()<UITextViewDelegate,selectIndexPathDelegate>

@property(nonatomic, strong) UIView   *controlView;
@property (strong, nonatomic) InfoView *infoView;
@property (nonatomic, strong) UIView *shadeView; ///< 遮罩层
@property(nonatomic, strong) UIButton *smallBtn;
@property(nonatomic, strong) UIButton *bigBtn;
@property(nonatomic, strong) UIButton *cancelBtn;
@property(nonatomic, strong) UITextView *logTextView;
@property(nonatomic, strong) UIButton *lineMarkBtn;  // 添加断位线
@property(nonatomic, strong) UIStepper *step;       //文字大小
@property(nonatomic, strong) UIButton *clearBtn;    // 清空当前

@property(nonatomic, assign) CGFloat currentScale;
@property(nonatomic, strong) GetLogFile *fieGet;
@property(nonatomic, copy)   NSString *logPath;
@property(nonatomic, assign) BOOL bDrag;
@property(nonatomic, assign) CGRect customFrame;
@property(nonatomic,strong) dispatch_queue_t logQueue;
@property(nonatomic,strong) NSFileHandle *readFile;
@property(nonatomic,assign) long long fileEndset;
@end

@implementation ZJLogTextView

static ZJLogTextView *manger = nil;

+ (id)addDebugViewWithAlpha:(CGFloat)alpha
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manger = [[ZJLogTextView alloc] initWithFrame:CGRectMake(5, 140, [UIScreen mainScreen].bounds.size.width - 10, [UIScreen mainScreen].bounds.size.height - 200)];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow addSubview:manger];
        });
        
        manger.hidden = YES;
        manger.alpha = alpha;
    });
    
    return manger;
}


- (void)logNotification
{
    [self getLogFile];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _customFrame = frame;
        _bDrag = NO;
        _fileEndset = 0;
        self.backgroundColor = [UIColor blackColor];
//        self.alpha = 0.5;
        [self.controlView addSubview:self.cancelBtn];
        [self.controlView addSubview:self.bigBtn];
        [self.controlView addSubview:self.smallBtn];
        [self.controlView addSubview:self.lineMarkBtn];
        [self.controlView addSubview:self.step];
        [self.controlView addSubview:self.clearBtn];
        [self addSubview:self.controlView];
        
        [self addSubview:self.infoView];
        [self addSubview:self.logTextView];
        
        // keyWindow
        UIWindow *_keyWindow = [UIApplication sharedApplication].keyWindow;
        
        // shadeView
        _shadeView = [[UIView alloc] initWithFrame:_keyWindow.bounds];
        _shadeView.backgroundColor = [UIColor clearColor];
        
        _currentScale = 1.0;

        _logQueue = dispatch_queue_create("logqueue", DISPATCH_QUEUE_SERIAL);
        UIPinchGestureRecognizer* pinGesture = [[UIPinchGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(scaleTextView:)];
        [self addGestureRecognizer:pinGesture];
        
         _fieGet = [[GetLogFile alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logNotification) name:@"LOGNOTIFICATION" object:nil];
          [_fieGet getLogFileData:^(NSString *logDataStr,NSString *filepath) {
            _logPath = filepath;
              
          }];
    }
    return self;
}

- (void)getLogFile
{
   dispatch_async(_logQueue, ^{
     dispatch_async(dispatch_get_main_queue(), ^{
         

         if (_fileEndset == 0) {
             _logTextView.text = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:_logPath] encoding:NSUTF8StringEncoding];
         }else
         {
             [_readFile seekToFileOffset:_fileEndset]; // 如果有清除处理，将指针先移到上次清除位置点
            _logTextView.text = [[NSString alloc] initWithData:[_readFile readDataToEndOfFile] encoding:NSUTF8StringEncoding];

         }
     });

 });
    
}

- (void)showDebugView
{
    // 弹出动画
    CGRect oldFrame = self.frame;
    self.frame = oldFrame;
    self.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    [UIView animateWithDuration:0.25f animations:^{
        self.transform = CGAffineTransformIdentity;
        _shadeView.alpha = 1.f;
    }];
    manger.hidden = NO;
    if (_fileEndset == 0) {
        manger.logTextView.text = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:manger.logPath] encoding:NSUTF8StringEncoding];
    }else
    {
        [_readFile seekToFileOffset:_fileEndset];
        manger.logTextView.text = [[NSString alloc] initWithData:[_readFile readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    }
    
    [_infoView show:_publishUrl];
}

- (void)dismissDebugView
{
    [UIView animateWithDuration:0.25f animations:^{
        _shadeView.alpha = 0.f;
        self.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    } completion:^(BOOL finished) {
        [_shadeView removeFromSuperview];
        manger.hidden = YES;
    }];
    manger.logTextView.text = @"";

}

- (void)scaleTextView:(UIPinchGestureRecognizer *)paramSender
{
    if (paramSender.state == UIGestureRecognizerStateEnded) {
        self.currentScale = paramSender.scale;
    }else if(paramSender.state == UIGestureRecognizerStateBegan && self.currentScale != 0.0f){
        paramSender.scale = self.currentScale;
    }
    if (paramSender.scale !=NAN && paramSender.scale != 0.0) {
        paramSender.view.transform = CGAffineTransformMakeScale(paramSender.scale, paramSender.scale);
    }
    CGFloat scale = paramSender.scale;

    self.transform = CGAffineTransformMakeScale(scale, scale);
}

- (UITextView *)logTextView
{
    if (_logTextView == nil) {
        _logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_controlView.frame) + CGRectGetHeight(_infoView.frame), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - CGRectGetHeight(_controlView.frame) - CGRectGetHeight(_infoView.frame))];
        _logTextView.textColor = [UIColor whiteColor];
        _logTextView.font = [UIFont systemFontOfSize:10];
        _logTextView.backgroundColor = [UIColor blackColor];
        
    }
//    _logTextView.userInteractionEnabled = NO; // 不能编辑 不能交互
    _logTextView.editable = NO;  // 不能编辑 能交互
    _logTextView.delegate = self;
    _logTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    return _logTextView;
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    
    CGPoint currentPoint= [touch locationInView:self];
    CGPoint prePoint = [touch previousLocationInView:self];
    
    CGFloat offsetx = currentPoint.x - prePoint.x;
    CGFloat offsety = currentPoint.y - prePoint.y;

    self.center = CGPointMake(self.center.x+offsetx, self.center.y+offsety);
    _customFrame = self.frame;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    CGFloat contenHeight=scrollView.contentSize.height;
    CGFloat refreshOffSet=scrollView.contentOffset.y+CGRectGetHeight(scrollView.frame);
    if(refreshOffSet==contenHeight)
    {
        _bDrag = NO;
    }else
    {
       _bDrag = YES;
    }    
}

- (UIView *)controlView{

    if (_controlView == nil) {
        _controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), BUTTON_HIGHT + 4)];
    }
    _controlView.backgroundColor = [UIColor lightGrayColor];
    _controlView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    return _controlView;
    
}

- (UIView *)infoView
{
    if (_infoView == nil) {
        _infoView = [[InfoView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_controlView.frame), CGRectGetWidth(self.frame), 150)];
    }
    _infoView.backgroundColor = [UIColor lightGrayColor];
    _infoView.alpha = 0.75;
    _infoView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
    return _infoView;
}

- (UIButton *)lineMarkBtn
{
    if (_lineMarkBtn == nil) {
        
        _lineMarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _lineMarkBtn.frame = CGRectMake(CGRectGetMaxX(_smallBtn.frame)+10, 2, BUTTON_HIGHT + 8, BUTTON_HIGHT);
    }
    [_lineMarkBtn setTitle:@"断位线" forState:UIControlStateNormal];
    _lineMarkBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [_lineMarkBtn addTarget:self action:@selector(lineMarkShow:) forControlEvents:UIControlEventTouchUpInside];
    
    return _lineMarkBtn;
}
- (UIButton *)smallBtn
{
    if (_smallBtn == nil) {
        _smallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _smallBtn.frame = CGRectMake(CGRectGetMaxX(_bigBtn.frame)+2, 2, BUTTON_HIGHT, BUTTON_HIGHT);
    }
    [_smallBtn setImage:[UIImage imageNamed:@"LogImageSource.bundle/small"] forState:UIControlStateNormal];
    [_smallBtn addTarget:self action:@selector(smallLogViewShow:) forControlEvents:UIControlEventTouchUpInside];

    return _smallBtn;
}

- (UIButton *)bigBtn
{
    if (_bigBtn == nil) {
        _bigBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _bigBtn.frame = CGRectMake(CGRectGetMaxX(_cancelBtn.frame)+2, 2, BUTTON_HIGHT, BUTTON_HIGHT);
    }
    [_bigBtn setImage:[UIImage imageNamed:@"LogImageSource.bundle/big"] forState:UIControlStateNormal];
    [_bigBtn addTarget:self action:@selector(bigLogViewShow:) forControlEvents:UIControlEventTouchUpInside];

    return _bigBtn;
}

- (UIButton *)cancelBtn
{
    if (_cancelBtn == nil) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.frame = CGRectMake(2, 2, BUTTON_HIGHT, BUTTON_HIGHT);
    }
    [_cancelBtn setImage:[UIImage imageNamed:@"LogImageSource.bundle/close"] forState:UIControlStateNormal];
    [_cancelBtn addTarget:self action:@selector(cancelLogViewShow:) forControlEvents:UIControlEventTouchUpInside];
    
    return _cancelBtn;
}

- (UIButton *)clearBtn
{
    if (_clearBtn == nil) {
        _clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearBtn setTitle:@"清屏" forState:UIControlStateNormal];
        _clearBtn.frame = CGRectMake(CGRectGetMaxX(_step.frame), 0, 40, BUTTON_HIGHT);
    }
    _clearBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    [_clearBtn addTarget:self action:@selector(clearScreen:) forControlEvents:UIControlEventTouchUpInside];
    return _clearBtn;
}
- (UIStepper *)step
{
    if (_step == nil) {
        _step = [[UIStepper alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_lineMarkBtn.frame)+10, 2, 20, BUTTON_HIGHT)];
        
        _step.minimumValue = 5.0f;
        _step.maximumValue = 30.0f;
        _step.value = 10;
    }
    
    [_step addTarget:self action:@selector(changeFont:) forControlEvents:UIControlEventValueChanged];
    
    return _step;
}

- (void)clearScreen:(UIButton *)sender
{
    // 清空当前显示内容 记录文件指针偏移位置
    _logTextView.text = @"";
    _readFile = [NSFileHandle fileHandleForReadingAtPath:_logPath];
    long long fileLength = [[_readFile availableData] length];
    _fileEndset = fileLength;
    
    
}
- (void)changeFont:(UIStepper *)sender
{

    _logTextView.font = [UIFont systemFontOfSize:sender.value];

}

- (void)cancelLogViewShow:(UIButton *)sender
{
    _logTextView.text = @"";
    manger.hidden = YES;
    
}

- (void)bigLogViewShow:(UIButton *)sender
{
    self.frame = _customFrame;
    
}
- (void)smallLogViewShow:(UIButton *)sender
{
    // 最小化时 暂停计时器 降低CPU
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, BUTTON_HIGHT *3 + 12, BUTTON_HIGHT);
}

- (void)lineMarkShow:(UIButton*)sender
{
    CGPoint point = CGPointMake(sender.center.x,sender.frame.origin.y+BUTTON_HIGHT);
    
    XTPopView *view1 = [[XTPopView alloc] initWithOrigin:point Width:130 Height:40 * 4 Type:XTTypeOfUpCenter Color:[UIColor colorWithRed:0.2737 green:0.2737 blue:0.2737 alpha:1.0]];
    view1.dataArray = @[@"-------------",
                        @"##########",
                        @"************",
                        @"++++++++++"];
    view1.fontSize = 13;
    view1.row_height = 40;
    view1.titleTextColor = [UIColor whiteColor];
    view1.delegate = self;
    [view1 popViewInView:self];
}
- (void)selectIndexPathRow:(NSInteger)index
{
    switch (index) {
        case 0:NSLog(@"--------------mark-------------------------");break;
        case 1:NSLog(@"##############mark####################");break;
        case 2:NSLog(@"*************************mark*******************");break;
        case 3:NSLog(@"++++++++++++++mark+++++++++++++++++++++++++++++++++");break;
    }
}


@end
