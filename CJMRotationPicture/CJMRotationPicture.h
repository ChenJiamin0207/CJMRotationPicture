//
//  CJMRotationPicture.h
//  CJMRotationPicture
//
//  Created by 行云流水 on 2018/4/20.
//  Copyright © 2018年 行云流水. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 选中图片完成处理
 
 @param nPicture 选中的第几张图片
 */
typedef void(^ selectCompletion)(NSInteger nPicture);


/**
 轮播图
 */
@interface CJMRotationPicture : UIView


/**
 初始化方法
 
 @param frame 布局
 @param complete 选择处理
 @return 实例化对象
 */
- (instancetype)initWithFrame:(CGRect)frame selectComplete:(selectCompletion)complete;

/**
 更新轮播图，支持 UIImage 数组 或 图片地址 NSString 数组
 
 @param arrPicture 图片数据
 */
- (void)updateDataWithPictureArray:(NSArray *)arrPicture;

@end
