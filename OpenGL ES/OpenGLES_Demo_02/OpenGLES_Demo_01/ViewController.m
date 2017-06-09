//
//  ViewController.m
//  OpenGLES_Demo_01
//
//  Created by 奔跑宝BPB on 2017/6/8.
//  Copyright © 2017年 benpaobao_mac. All rights reserved.
//

#import "ViewController.h"

#import "OpenGLESView.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    OpenGLESView *glView = [[OpenGLESView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:glView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
