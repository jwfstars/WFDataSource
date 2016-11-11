//
//  ViewController.m
//  WFDataSourceDemo
//
//  Created by 江文帆 on 16/11/11.
//  Copyright © 2016年 江文帆. All rights reserved.
//

#import "ViewController.h"
#import "WFDataSource.h"
#import "DemoCell.h"
#import "DemoCell_XIB.h"

@interface ViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WFDataSource *dataSource;
@end

@implementation ViewController

- (void)loadView
{
    self.view = self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        tableView;
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = ({
        NSDictionary *modelCellMap = @{
                                       @"":@"",
                                       @"":@"",
                                       };
        WFDataSource *dataSource = [[WFDataSource alloc] initWithModelCellMap:@{} configureCellBlock:^(id cell, id item, NSIndexPath *indexPath) {
            
        }];
        dataSource;
    });
    self.dataSource.tableView = self.tableView;
}



@end
