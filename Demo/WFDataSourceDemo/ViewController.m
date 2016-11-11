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
#import "DemoCellModel_XIB.h"
#import "DemoCellModel.h"

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
    self.title = @"WFDataSource";
    
    self.dataSource = ({
        NSDictionary *modelCellMap = @{
                                       @"DemoCellModel":@"DemoCell",
                                       @"DemoCellModel_XIB":@"DemoCell_XIB",
                                       };
        WFDataSource *dataSource = [[WFDataSource alloc] initWithModelCellMap:modelCellMap configureCellBlock:^(id cell, id item, NSIndexPath *indexPath) {
            [cell configCellWithItem:item];
        }];
        dataSource.headerViewForSection = ^ UIView *(id sectionItem, NSInteger section){
            ArrayDSDefaultSection *sectionData = (ArrayDSDefaultSection *)sectionItem;
            if (sectionData.sectionTitle) {
                UIView *bg = [UIView new];
                bg.frame = CGRectMake(0, 0, 0, 30);
                bg.backgroundColor = [UIColor lightGrayColor];
                
                UILabel *label = [UILabel new];
                label.frame = CGRectMake(10, 0, 100, 30);
                label.text = sectionData.sectionTitle;
                [bg addSubview:label];
                return bg;
            }
            return nil;
        };
        dataSource.didSelectCellBlock = ^(id item, NSIndexPath *indexPath) {
            NSLog(@"%@ - section %@, row %@",item, @(indexPath.section), @(indexPath.row));
        };
        dataSource.heightForRow = ^CGFloat (id item, NSIndexPath *indexPath) {
            if ([item isKindOfClass:[DemoCellModel class]]) {
                DemoCellModel *cellModel = (DemoCellModel *)item;
                return cellModel.cellHeight;
            }else if ([item isKindOfClass:[DemoCellModel_XIB class]]) {
                return UITableViewAutomaticDimension;
            }else {
                return 44;
            }
        };
        dataSource.doNotUseXib = YES;
        dataSource;
    });
    
    self.tableView.estimatedRowHeight = 44;
    self.dataSource.tableView = self.tableView;
    
    [self.dataSource reloadWithSectionItems:[self setupSectionModels]];
    
//    [self.dataSource reloadWithItems:[self setupModels]];
}


- (NSArray *)setupSectionModels
{
    NSMutableArray *modelArray1 = [NSMutableArray array];
    for (NSInteger i=0; i<5; i++) {
        DemoCellModel *model = [DemoCellModel new];
        model.name = [NSString stringWithFormat:@"Name-%@",@(i)];
        model.imageName = [NSString stringWithFormat:@"%@.png",@(i)];
        [modelArray1 addObject:model];
    }
    
    NSMutableArray *modelArray2 = [NSMutableArray array];
    for (NSInteger i=0; i<8; i++) {
        DemoCellModel_XIB *model = [DemoCellModel_XIB new];
        model.title = [NSString stringWithFormat:@"Title-%@",@(i)];
        NSMutableString *stringM = [NSMutableString string];
        for (NSInteger j=0; j<i+1; j++) {
            [stringM appendString:@"This is a long string. "];
        }
        model.subTitle = [stringM copy];
        [modelArray2 addObject:model];
    }
    
    ArrayDSDefaultSection *section1 = [ArrayDSDefaultSection new];
    section1.sectionItems = modelArray1;
    section1.sectionTitle = @"Section 1";
    
    ArrayDSDefaultSection *section2 = [ArrayDSDefaultSection new];
    section2.sectionItems = modelArray2;
    section2.sectionTitle = @"Section 2";
    
    return @[section1];
    return @[section1, section2];
}

- (NSArray *)setupModels
{
    NSMutableArray *modelArray1 = [NSMutableArray array];
    for (NSInteger i=0; i<5; i++) {
        DemoCellModel *model = [DemoCellModel new];
        model.name = [NSString stringWithFormat:@"name-%@",@(i)];
        model.imageName = [NSString stringWithFormat:@"%@.png",@(i)];
        [modelArray1 addObject:model];
    }
    return modelArray1;
}
@end
