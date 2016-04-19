//
//  TSRefreshView.m
//  TableViewPerformance
//
//  Created by tunsuy on 31/3/16.
//  Copyright © 2016年 tunsuy. All rights reserved.
//

#import "TSRefreshView.h"

@interface TSRefreshView()

@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UILabel *tip;

@end

@implementation TSRefreshView

//第一种：直接在该方法中定义frame
//- (instancetype)initWithFrame:(CGRect)frame {
//    if (self = [super initWithFrame:frame]) {
//        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        activityView.frame = CGRectMake(20.0f, 10.0f, 20.0f, 20.0f);
//        [self addSubview:activityView];
//        _activityView = activityView;
//        
//        UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 10.0f, 100.0f, 20.0f)];
//        tip.font = [UIFont systemFontOfSize:14];
//        tip.text = @"加载中...";
//        [self addSubview:tip];
//        _tip = tip;
//    }
//    return self;
//}

//第二种：采用懒加载方式
#pragma mark - 懒加载
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
//        [self addSubview:_activityView];
//        [self addSubview:_tip];
        [self addSubview:self.activityView];//只有这样才会调用setter方法
        [self addSubview:self.tip];
    }
    return self;
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    [self addSubview:self.activityView];
//    [self addSubview:self.tip];
//}

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityView.frame = CGRectMake(20.0f, 10.0f, 20.0f, 20.0f);
//        [self addSubview:activityView];
        _activityView = activityView;
        [_activityView startAnimating];
    }
    return _activityView;
}

- (UILabel *)tip {
    if (!_tip) {
        UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 10.0f, 100.0f, 20.0f)];
        tip.font = [UIFont systemFontOfSize:14];
        tip.text = @"加载中...";
//        [self addSubview:tip];
        _tip = tip;
    }
    return _tip;
}

@end
