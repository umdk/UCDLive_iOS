//
//  RadioGroup.m
//
//  Created by 凌洛寒 on 14-5-14.
//  Copyright (c) 2014年 凌洛寒. All rights reserved.
//

#import "RadioGroup.h"
#import "RadioBox.h"

@interface RadioGroup ()

- (void)handleSwitchEvent:(id)sender;

@end

@implementation RadioGroup

- (id)initWithFrame:(CGRect)frame WithControl:(NSArray*)controls
{
    self = [super initWithFrame:frame];
    if (self) {
        for (id control in controls) {
            [self addSubview:control];
        }
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(void)setTintColor:(UIColor *)tintColor
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setTintColor:tintColor];
        }
    }
    _tintColor = tintColor;
}

-(void)setOnTintColor:(UIColor *)onTintColor
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setOnTintColor:onTintColor];
        }
    }
    _onTintColor = onTintColor;
}

-(void)setBoxBgColor:(UIColor *)boxBgColor
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setBoxBgColor:boxBgColor];
        }
    }
    _boxBgColor = boxBgColor;
}

-(void)setBoxColor:(UIColor *)boxColor
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setBoxColor:boxColor];
        }
    }
    _boxColor = boxColor;
}

-(void)setTextColor:(UIColor *)textColor
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setTextColor:textColor];
        }
    }
    _textColor = textColor;
}

-(void)setTextFont:(UIFont *)textFont
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control setTextFont:textFont];
        }
    }
    _textFont = textFont;
}

- (void)setSelectValue:(NSInteger)selectValue
{
    if (_selectValue == 0) {
        for (UIView *control in self.subviews) {
            if ([control isKindOfClass:[RadioBox class]]) {
                if (((RadioBox*)control).value == selectValue) {
//                    [(RadioBox*)control setIsClick:YES];
                    [(RadioBox*)control setIsOn:YES];
                }
            }
        }
    }
    _selectValue = selectValue;
}


- (void)commonInit
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            [(RadioBox*)control addTarget:self action:@selector(handleSwitchEvent:) forControlEvents:UIControlEventValueChanged];
        }
    }
}

- (void)handleSwitchEvent:(id)sender
{
    for (UIView *control in self.subviews) {
        if ([control isKindOfClass:[RadioBox class]]) {
            if (((RadioBox*)control).isOn) {
                self.selectText = ((RadioBox*)control).text;
                self.selectValue = ((RadioBox*)control).value;
                continue;
            }
            if ([self.subviews indexOfObject:control] != [self.subviews indexOfObject:sender]) {
//                [(RadioBox*)control setIsClick:NO];
                NSLog(@"radioBox is not click");
//                if (((RadioBox*)control).isOn) {
                    [(RadioBox*)control setIsOn:NO];
//                }
            }
            else
            {
                NSLog(@"randioBox is click");
                self.selectText = ((RadioBox*)control).text;
                self.selectValue = ((RadioBox*)control).value;
            }
        }
    }
    
    if (_radioDelegate && [_radioDelegate respondsToSelector:@selector(selectedBox:)]) {
        [_radioDelegate selectedBox:self];
    }
}

@end
