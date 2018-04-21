# CJMRotationPicture
轮播图几乎是每一个 App 都会有的功能，而在 UIKit 中又找不到能够直接实现轮播图的视图控件。因此我们需要通过组合视图控件的方法去实现轮播。

首先分析轮播图的结构组成，从静止上看，轮播图就是在一个横向的滚动视图上添加了几张图片，然后在滚动视图的底部添加一个页码控制器来监听滚动视图显示的是第几张图片，接下来的循环滚动，只需要添加一个定时器来让滚动视图有序地进行轮回滚动。

考虑到视图的复用性和点击触发事件，我们使用 UICollectionView 作为主控件，设置翻页的横向滚动，在 UICollectionViewCell 上添加和 UICollectionView 一样大小的 UIImageView。为了让封装之后的轮播图类方便在视图控制器上的使用，将这个类继承于 UIView，UICollectionView 和页码控制器 UIPageControl 的布局将在类的初始化实现。为了能够让轮播图的点击事件得到响应，在初始化的时候，传入一个可以处理用户点击了第几张轮播图片的 block。

不多说了，直接上代码。
接口头文件 CJMRotationPictureController.h：
 ```
/**
 选中图片完成处理
 
 @param nPicture 选中的第几张图片
 */
typedef void(^ selectCompletion)(NSInteger nPicture);


/**
 轮播图
 */
@interface CJMRotationPictureController : UIView


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
```
实现文件 CJMRotationPictureController.m：
```
// 主视图的长宽
#define kViewWidth self.frame.size.width
#define kViewHeight self.frame.size.height

static NSString *gPictureID = @"PictureID";

@interface CJMRotationPictureController () <UICollectionViewDelegate, UICollectionViewDataSource>

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


@implementation CJMRotationPictureController


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
    
    UICollectionView *collectTemp = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kViewWidth, kViewHeight) collectionViewLayout:flowLayout];
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

@end
```
在视图控制器上的调用：
```
CJMRotationPictureController *rotation = [[CJMRotationPictureController alloc] initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenWidth/2) selectComplete:^(NSInteger nPicture) {
       
        NSLog(@"点击了第%ld图片", nPicture);
}];
[self.view addSubview:rotation];
    
// 载入图片
[rotation updateDataWithPictureArray:@[[UIImage imageNamed:@"desk1"], [UIImage imageNamed:@"test2"], [UIImage imageNamed:@"desk1"], [UIImage imageNamed:@"test2"]]];
```
结果截图：
![轮播图](https://upload-images.jianshu.io/upload_images/3892076-154de0e042cf9d10.gif?imageMogr2/auto-orient/strip)

[GitHub 上的代码](https://github.com/ChenJiamin0207/CJMRotationPicture)
使用 CocoaPods 集成：
```
pod 'CJMRotationPicture'
```