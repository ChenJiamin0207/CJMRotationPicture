//
//  ViewController.m
//  Example
//
//  Created by 行云流水 on 2018/4/20.
//  Copyright © 2018年 行云流水. All rights reserved.
//

#import "ViewController.h"
#import "CJMRotationPicture.h"


// 屏幕的宽和高
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // test
    CJMRotationPictureController *rotation = [[CJMRotationPictureController alloc] initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenWidth/2) selectComplete:^(NSInteger nPicture) {
       
        NSLog(@"点击了第%ld图片", nPicture);
    }];
    [self.view addSubview:rotation];
    
    // 载入图片
    [rotation updateDataWithPictureArray:@[[UIImage imageNamed:@"desk1"], [UIImage imageNamed:@"test2"], [UIImage imageNamed:@"desk1"], [UIImage imageNamed:@"test2"]]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
