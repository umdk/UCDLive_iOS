//
//  FilterPopoverViewCell.h
//  Popover
//
//  Created by Sidney on 03/05/17.
//  Copyright © 2017年 lifution. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopoverAction.h"

UIKIT_EXTERN float const PopoverViewCellHorizontalMargin; ///< 水平间距边距
UIKIT_EXTERN float const PopoverViewCellVerticalMargin; ///< 垂直边距
UIKIT_EXTERN float const PopoverViewCellTitleLeftEdge; ///< 标题左边边距

@interface FilterPopoverViewCell : UITableViewCell

@property (nonatomic, assign) PopoverViewStyle style;

/*! @brief 标题字体
 */
+ (UIFont *)titleFont;

/*! @brief 底部线条颜色
 */
+ (UIColor *)bottomLineColorForStyle:(PopoverViewStyle)style;

- (void)setAction:(PopoverAction *)action;

- (void)showBottomLine:(BOOL)show;

@end
