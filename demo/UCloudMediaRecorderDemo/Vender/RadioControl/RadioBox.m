//
//  RadioBox.m
//
//  Created by 凌洛寒 on 14-5-14.
//  Copyright (c) 2014年 凌洛寒. All rights reserved.
//

#import "RadioBox.h"


#define RadioBoxMaxWidth 31.0f
#define RadioBoxMinWidth 20.0f

@interface RadioBox ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *onBoxView;
@property (nonatomic, strong) UIView *offBoxView;
//@property (nonatomic, strong) UIView *offKnobView;
@property (nonatomic, strong) UIView *knobView;
@property (nonatomic, strong) UILabel *lbText;

- (void)commonInit;

- (CGRect)roundRect:(CGRect)frameOrBounds;

- (void)handleTapTapGestureRecognizerEvent:(UITapGestureRecognizer *)recognizer;

@end

@implementation RadioBox

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:[self roundRect:frame]];
    if (self) {
        [self commonInit];
//        self.isClick = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
//        self.isClick = NO;
    }
    
    return self;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:[self roundRect:bounds]];
    
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:[self roundRect:frame]];
    
    [self setNeedsLayout];
}


-(void)setText:(NSString *)text
{
    if (_text != text) {
        _text = text;
        
        _lbText.text = text;
    }
}

-(void)setTextColor:(UIColor *)textColor
{
    _lbText.textColor = textColor;
}

-(void)setTextFont:(UIFont *)textFont
{
    _lbText.font = textFont;
}

- (void)setOnTintColor:(UIColor *)onTintColor
{
    if (_onTintColor != onTintColor) {
        _onTintColor = onTintColor;
        
        _onBoxView.backgroundColor = onTintColor;
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    if (_tintColor != tintColor) {
        _tintColor = tintColor;
        
        _offBoxView.backgroundColor = tintColor;
    }
}


- (void)setBoxColor:(UIColor *)boxColor
{
    if (_boxColor != boxColor) {
        _boxColor = boxColor;
        
        _knobView.backgroundColor = _boxColor;
    }
}

- (void)setBoxBgColor:(UIColor *)boxBgColor
{
    if (_boxBgColor != boxBgColor) {
        _boxBgColor = boxBgColor;
        
//        _offKnobView.backgroundColor = _boxBgColor;
    }
}



- (CGRect)roundRect:(CGRect)frameOrBounds
{
    CGRect newRect = frameOrBounds;
    
    if (newRect.size.height > RadioBoxMaxWidth) {
        newRect.size.height = RadioBoxMaxWidth;
    }
    
    if (newRect.size.height < RadioBoxMinWidth) {
        newRect.size.height = RadioBoxMinWidth;
    }
    
    if (newRect.size.width < RadioBoxMinWidth) {
        newRect.size.width = RadioBoxMinWidth;
    }
    
    return newRect;
}



- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
    
    _onTintColor = [UIColor colorWithRed:0.176 green:0.334 blue:0.852 alpha:1.000];
    _tintColor = [UIColor colorWithRed:0.037 green:0.139 blue:0.167 alpha:1];
    _boxColor = [UIColor colorWithRed:0.897 green:0.177 blue:0.462 alpha:1.000];
    _boxBgColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    _containerView = [[UIView alloc] initWithFrame:self.bounds];
    _containerView.backgroundColor = [UIColor clearColor];
    [self addSubview:_containerView];
    
    _onBoxView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds))];
    _onBoxView.backgroundColor = _onTintColor;
    _onBoxView.layer.cornerRadius = CGRectGetHeight(self.containerView.bounds) / 2.0;
    [_containerView addSubview:_onBoxView];
    
    _offBoxView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds))];
    _offBoxView.backgroundColor = _tintColor;
    _offBoxView.layer.cornerRadius = CGRectGetHeight(self.containerView.bounds) / 2.0;
    [_containerView addSubview:_offBoxView];
    
    
    CGFloat _boxWidth = CGRectGetHeight(self.containerView.bounds)-8;
    CGFloat margin = (CGRectGetHeight(self.bounds) - _boxWidth) / 2.0;
    
//    _offKnobView = [[UIView alloc] initWithFrame:CGRectMake(margin, margin, _boxWidth, _boxWidth)];
//    _offKnobView.backgroundColor = _boxBgColor;
//    _offKnobView.layer.cornerRadius = _boxWidth / 2.0;
//    [_containerView addSubview:_offKnobView];
    
    
    _knobView = [[UIView alloc] initWithFrame:CGRectMake(margin, margin, _boxWidth, _boxWidth)];
    _knobView.backgroundColor = _boxColor;
    _knobView.layer.cornerRadius = _boxWidth / 2.0;
    [_containerView addSubview:_knobView];
    
    
    CGFloat _labelMarginLeft = CGRectGetHeight(self.containerView.bounds) + 10;
    CGFloat _labelWidth = CGRectGetWidth(self.containerView.bounds) - _labelMarginLeft;
    
    _lbText = [[UILabel alloc] initWithFrame:CGRectMake(_labelMarginLeft, 0, _labelWidth, CGRectGetHeight(self.containerView.bounds))];
    _lbText.backgroundColor = [UIColor clearColor];
    _lbText.textAlignment = NSTextAlignmentLeft;
    _lbText.textColor = _textColor;
    _lbText.font = _textFont;
    _lbText.text = _text;
    [_containerView addSubview:_lbText];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleTapTapGestureRecognizerEvent:)];
    [self addGestureRecognizer:tapGesture];
}


- (void)layoutSubviews
{
    NSLog(@"layoutsubviews");
    [super layoutSubviews];
    
    self.containerView.frame = self.bounds;
    self.containerView.layer.masksToBounds = YES;
    
    CGFloat _boxWidth = CGRectGetHeight(self.containerView.bounds) - 8;
    CGFloat margin = (CGRectGetHeight(self.bounds) - _boxWidth) / 2.0;
    
    if (self.isOn) {
        // frame of on status
        
        self.knobView.frame = CGRectMake(margin, margin, _boxWidth, _boxWidth);
        
        self.onBoxView.frame = CGRectMake(0, 0,
                                          CGRectGetHeight(self.containerView.bounds),
                                          CGRectGetHeight(self.containerView.bounds));
        
        self.offBoxView.frame = CGRectMake(0, 0, 0, 0);
        
    } else {
        // frame of off status
        self.onBoxView.frame = CGRectMake(0, 0, 0, 0);
        
        self.offBoxView.frame = CGRectMake(0, 0,
                                           CGRectGetHeight(self.containerView.bounds),
                                           CGRectGetHeight(self.containerView.bounds));
        
        self.knobView.frame = CGRectMake(CGRectGetHeight(self.containerView.bounds) / 2,
                                         CGRectGetHeight(self.containerView.bounds) / 2, 0, 0);
    }

}



- (void)handleTapTapGestureRecognizerEvent:(UITapGestureRecognizer *)recognizer
{
//    if (self.isOn) {
//        return;
//    }

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setIsOn:!self.isOn];
//        self.isClick = YES;
    }
}

- (void)setIsOn:(BOOL)isOn
{
    CGFloat _boxWidth = CGRectGetHeight(self.containerView.bounds) - 8;
    CGFloat margin = (CGRectGetHeight(self.bounds) - _boxWidth) / 2.0;
    
    NSLog(@"isOn = %d", self.isOn);
    
    if (self.isOn) {
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.knobView.frame = CGRectMake(margin, margin, _boxWidth, _boxWidth);
                         }
                         completion:^(BOOL finished){
                             self.onBoxView.frame = CGRectMake(0, 0,
                                                                   CGRectGetHeight(self.containerView.bounds),
                                                                   CGRectGetHeight(self.containerView.bounds));
                             
                             self.offBoxView.frame = CGRectMake(0, 0, 0, 0);
                         }];
    } else {
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.knobView.frame = CGRectMake(CGRectGetHeight(self.containerView.bounds) / 2,
                                                              CGRectGetHeight(self.containerView.bounds) / 2, 0, 0);
                         }
                         completion:^(BOOL finished){
                             self.onBoxView.frame = CGRectMake(0, 0, 0, 0);
                             
                             self.offBoxView.frame = CGRectMake(0, 0,
                                                                    CGRectGetHeight(self.containerView.bounds),
                                                                    CGRectGetHeight(self.containerView.bounds));
                         }];
    }
    //NSLog(@"label:%f,view:%f",self.lbText.frame.size.height,CGRectGetHeight(self.containerView.bounds));
    
    if (_isOn == isOn) {
        return;
    }
    _isOn = isOn;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
