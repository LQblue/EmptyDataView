//
//  ViewController.m
//  TestEmptyData
//
//  Created by liqi on 2018/6/1.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "ViewController.h"
//
//#import "UIScrollView+EmptyDataSet.h"
#import "UIScrollView+SEmptyDataSet.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, SEmptyDataSetSource, SEmptyDataSetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) NSInteger numbers;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.s_emptyDataSetSource = self;
    self.tableView.s_emptyDataSetDelegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (IBAction)clickBtn1:(UIButton *)sender
{
    self.numbers = 30;
    [self.tableView reloadData];
}

- (IBAction)clickBtn2:(UIButton *)sender
{
    self.numbers = 0;
    [self.tableView reloadData];
}
#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.numbers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor redColor];
    }
    else {
        cell.backgroundColor = [UIColor orangeColor];
    }
    return cell;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)s_titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"没有数据！" attributes:nil];
    return str;
}

- (NSAttributedString *)s_descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"没有数据没有数据没有数据没有数据没有数据没有数据没有数据没有数据没有数据！" attributes:nil];
    return str;
}

//- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
//{
//    return -200;
//}

- (UIColor *)s_backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor redColor];
}

#pragma mark - DZNEmptyDataSetSource

- (BOOL)s_emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)s_emptyDataSetShouldFadeIn:(UIScrollView *)scrollView
{
    return YES;
}

@end
