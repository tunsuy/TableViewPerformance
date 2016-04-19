//
//  ViewController.m
//  TableViewPerformance
//
//  Created by tunsuy on 31/3/16.
//  Copyright © 2016年 tunsuy. All rights reserved.
//

#import "ViewController.h"
#import "TSRefreshView.h"
#import <objc/runtime.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define kCellCount 5
#define kCellMargin 10
#define kFontForText 18

#define kPageNumber 2

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TSRefreshView *refreshView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) NSArray *cellHeightCache;

@property (nonatomic) BOOL isHasMore;
@property (nonatomic) BOOL isFirstTime;
@property (nonatomic) NSInteger currentCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, SCREEN_WIDTH, SCREEN_HEIGHT-44) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    CGFloat height = MAX(_tableView.contentSize.height, _tableView.frame.size.height);
    _refreshView = [[TSRefreshView alloc] initWithFrame:CGRectMake(0, height, SCREEN_WIDTH, 30)];
//    [_tableView addSubview:_refreshView];
    _tableView.tableFooterView = _refreshView;
    _currentCount = kPageNumber;
    _isHasMore = YES;
    _isFirstTime = YES;
    
    _dataArr = [self generateCellDataFromDataArrWithDataCount:_currentCount];
    _cellHeightCache = [self caCheCellHeight];
    
}

- (NSArray *)DataFromPlistFile {
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"TableViewData" ofType:@"plist"];
    NSArray *dataArr = [NSArray arrayWithContentsOfFile:dataPath];
    return dataArr;
}

- (NSMutableArray *)generateCellDataFromDataArrWithDataCount:(NSInteger)dataCount {
    NSArray *fileDataArr = [self DataFromPlistFile];
    NSInteger fileDataArrCount = [fileDataArr count];
    NSInteger fileDataArrIndex;
    NSMutableArray *dataArr = [[NSMutableArray alloc] initWithCapacity:kCellCount];
    for (int i=0; i<dataCount; i++) {
        fileDataArrIndex = arc4random()%fileDataArrCount;
        [dataArr addObject:fileDataArr[fileDataArrIndex]];
    }
    return dataArr;
}

- (NSMutableArray *)caCheCellHeight {
    NSMutableArray *cellHeightCache = [[NSMutableArray alloc] initWithCapacity:kCellCount];
    for (int i=0; i<_currentCount; i++) {
        [cellHeightCache addObject:[NSNumber numberWithFloat:[self heightForText:_dataArr[i][@"data"]]]];
    }
    return cellHeightCache;
}

- (CGFloat)heightForText:(NSString *)text {
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:kFontForText] constrainedToSize:CGSizeMake(SCREEN_WIDTH-kCellMargin*2, MAXFLOAT)];
    return size.height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = _dataArr[indexPath.row][@"data"];
    cell.textLabel.font = [UIFont systemFontOfSize:kFontForText];
    cell.textLabel.numberOfLines = 0;
    
    [self checkMoreDataWithIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    第一种：直接在该方法内实时算出高度
//    NSString *cellData = _dataArr[indexPath.row][@"data"];
//    CGSize size = [cellData sizeWithFont:[UIFont systemFontOfSize:kFontForText] constrainedToSize:CGSizeMake(SCREEN_WIDTH-kCellMargin*2, MAXFLOAT)];
//    return size.height;
//    结果：再滑动复用的过程中，cpu经常占到90%左右，帧率下降到30%左右
    
//    第二种：调用外部高度实现方法
//    return [self heightForCellDataAtIndexPath:indexPath];
    
//    第三种：使用缓存高度
    return [_cellHeightCache[indexPath.row] floatValue];
    

}

- (CGFloat)heightForCellDataAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellData = _dataArr[indexPath.row][@"data"];
    return [self heightForText:cellData];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (void)checkMoreDataWithIndexPath:(NSIndexPath *)indexPath {
    if (!_isHasMore) {
        
        _tableView.tableFooterView = nil;
        return;
    }
    NSLog(@"_currentCount: %ld  --  indexPath.row: %ld", _currentCount, indexPath.row);
    if (_currentCount-1 == indexPath.row) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadMore];
        });
    }
}

- (void)loadMore {
    if (!_isFirstTime) {
        _tableView.tableFooterView = _refreshView;
    }
    NSInteger oldCount = _currentCount;
    _currentCount = _isFirstTime ? _currentCount : MIN(_currentCount+kPageNumber, kCellCount);
    _isHasMore = _currentCount>=kCellCount ? NO : YES;
    
    if (oldCount != _currentCount) {
        _isFirstTime = YES;
        NSInteger insertCount = _currentCount >= kCellCount ? kCellCount-oldCount : kPageNumber;
        NSArray *insertDataArr = [self generateCellDataFromDataArrWithDataCount:insertCount];
        [_dataArr addObjectsFromArray:insertDataArr];
        _cellHeightCache = [self caCheCellHeight];
        
//        _cellHeightCache = [self caCheCellHeight];
//        [_tableView reloadData];
        
        NSMutableArray *insertIndexPathArr = [[NSMutableArray alloc] init];
        for (int i=0; i<[insertDataArr count]; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_dataArr indexOfObject:insertDataArr[i]] inSection:0];
            [insertIndexPathArr addObject:indexPath];
        }
        [_tableView insertRowsAtIndexPaths:insertIndexPathArr withRowAnimation:NO];
    }
    
    _isFirstTime = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
