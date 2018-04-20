//
//  CJMRotationPicture.m
//  CJMRotationPicture
//
//  Created by 行云流水 on 2018/4/20.
//  Copyright © 2018年 行云流水. All rights reserved.
//

#import "CJMRotationPicture.h"


// 主视图的长宽
#define kViewWidth self.frame.size.width
#define kViewHeight self.frame.size.height

static NSString *gPictureID = @"PictureID";

@interface CJMRotationPicture () <UICollectionViewDelegate, UICollectionViewDataSource>

/**
 主集合图
 */
@property (nonatomic, weak) UICollectionView *collectMain;

/**
 页码控制器
 */
@property (nonatomic, weak) UIPageControl *pageShow;

/**
 数据源 UIImage 数组 或 图片地址 NSString 数组
 */
@property (nonatomic, strong) NSArray *arrDataSource;

/**
 滚动计时器
 */
@property (nonatomic, strong) NSTimer *timerScroll;

/**
 事件处理
 */
@property (nonatomic, copy) selectCompletion blockComplete;

@end


@implementation CJMRotationPicture

/**
 初始化方法

 @param frame 布局
 @param complete 选择处理
 @return 实例化对象
 */
- (instancetype)initWithFrame:(CGRect)frame selectComplete:(selectCompletion)complete {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self initLayout];
        self.blockComplete = complete;
    }
    return self;
}

- (void)initLayout {
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    
    // 主集合图
    // 自适应布局
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setMinimumLineSpacing:0];
    [flowLayout setMinimumInteritemSpacing:0];
    // 水平方向滚动
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setItemSize:self.frame.size];
    
    UICollectionView *collectTemp = [[UICollectionView alloc] initWithFrame:self.frame collectionViewLayout:flowLayout];
    [collectTemp setBackgroundColor:[UIColor whiteColor]];
    // 隐藏水平滚动条
    collectTemp.showsHorizontalScrollIndicator = NO;
    // 翻页效果
    collectTemp.pagingEnabled = YES;
    collectTemp.delegate = self;
    collectTemp.dataSource = self;
    [self addSubview:collectTemp];
    self.collectMain = collectTemp;
    // 注册cell
    [self.collectMain registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:gPictureID];
    
    
    // 页码控制器
    UIPageControl *pageTemp = [[UIPageControl alloc] initWithFrame:CGRectMake(kViewWidth * 0.8, kViewHeight - 30, kViewWidth/5, 30)];
    // 只有一页是隐藏
    [pageTemp setHidesForSinglePage:YES];
    // 普通颜色
    [pageTemp setPageIndicatorTintColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    // 当前页颜色
    [pageTemp setCurrentPageIndicatorTintColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [self addSubview:pageTemp];
    self.pageShow = pageTemp;
    
    self.arrDataSource = [NSArray array];
}


#pragma mark - UICollectionViewDataSourse 收集数据源处理
// 区域数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

// 单元数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [self.arrDataSource count];
}

// cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:gPictureID forIndexPath:indexPath];
    
    // 图片
    UIImageView *imgvPicture = (UIImageView *)[cell viewWithTag:10];
    if (imgvPicture == nil) {
        
        // 添加子控件
        imgvPicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kViewWidth, kViewHeight)];
        [imgvPicture setTag:10];
        [imgvPicture setClipsToBounds:YES];
        [imgvPicture setContentMode:UIViewContentModeScaleAspectFill];
        [cell addSubview:imgvPicture];
    }
    
    // 数组对象的类型
    if ([self.arrDataSource[indexPath.row] isKindOfClass:[UIImage class]]) {
        
        // UIImage
        [imgvPicture setImage:self.arrDataSource[indexPath.row]];
        
    } else if ([self.arrDataSource[indexPath.row] isKindOfClass:[NSString class]]) {
        
        // 图片地址的 NSString
        NSURL *urlImage = [NSURL URLWithString:self.arrDataSource[indexPath.row]];
        NSData *dataImage = [NSData dataWithContentsOfURL:urlImage];
        if (dataImage) {
            
            [imgvPicture setImage:[UIImage imageWithData:dataImage]];
        }
    }
    
    return cell;
}

// 选中项处理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // 通过委托传递选中序号
    self.blockComplete(indexPath.row);
}


#pragma mark - 对外接口
/**
 更新轮播图，支持 UIImage 数组 或 图片地址 NSString 数组
 
 @param arrPicture 图片数据
 */
- (void)updateDataWithPictureArray:(NSArray *)arrPicture {
    
    self.arrDataSource = arrPicture;
    // 页视图布局
    CGFloat fwidth = 13 * [self.arrDataSource count];
    [self.pageShow setFrame:CGRectMake(kViewWidth - 14 - fwidth, kViewHeight - 30, fwidth, 30)];
    // 总页数
    [self.pageShow setNumberOfPages:[self.arrDataSource count]];
    // 当前页
    [self.pageShow setCurrentPage:0];
    
    // 更新集合视图
    [self.collectMain reloadData];
    
    // 信息不少于2条是，启动计时器，否则停止计时器
    if ([self.arrDataSource count] > 2) {
        
        // 启动定时器
        [self fireScollerTimer];
    } else {
        
        // 关闭定时器
        if (self.timerScroll) {
            
            [self.timerScroll invalidate];
        }
    }
    
}


/**
 启动定时器
 */
- (void)fireScollerTimer {
    
    if (self.timerScroll == nil) {
        
        self.timerScroll = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(timerActionWithTimer:) userInfo:nil repeats:YES];
    }
    [[NSRunLoop currentRunLoop] addTimer:self.timerScroll forMode:NSRunLoopCommonModes];
}


/**
 定时器事件
 
 @param timer 定时器
 */
- (void)timerActionWithTimer:(NSTimer* )timer {
    
    // 通过改变滚动的滚动位置来达到切换的效果
    // 获取当前的所处的滚动位置
    float offset_x = self.collectMain.contentOffset.x;
    // 每次滚动一条
    offset_x += kViewWidth;
    
    // 滚屏宽度
    CGFloat scrollWidth = ([self.arrDataSource count] - 1) * kViewWidth;
    
    // 最后一条之后，回到第一条
    if (offset_x > scrollWidth) {
        
        // 最后的偏移量
        [self.collectMain setContentOffset:CGPointMake(0, 0) animated:NO];
    } else {
        
        [self.collectMain setContentOffset:CGPointMake(offset_x, 0) animated:YES];
    }
    
}

/**
 更新页码
 */
- (void)updataPageNumber {
    
    float offset_x = self.collectMain.contentOffset.x;
    [self.pageShow setCurrentPage:offset_x/kViewWidth];
}


#pragma mark - UIScrollViewDelegate 滚动监听
// 滚动视图开始被拖动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    // 定时器休眠
    [self.timerScroll setFireDate:[NSDate distantFuture]];
}

// 滚动视图静止
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    // 定时器 2 秒后重启
    [self.timerScroll setFireDate:[NSDate dateWithTimeInterval:2 sinceDate:[NSDate date]]];
}

// 滚动后--更新所滑到的页码
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // 更新页码
    [self updataPageNumber];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
