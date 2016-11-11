//
//  CollectionDataSources.h
//  Magazine
//
//  Created by 江文帆 on 15/9/14.
//  Copyright (c) 2015年 江文帆. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VGTEmptyCell.h"
#import "VGTErrorCell.h"
#import "VGTCellConfig.h"

typedef void (^CellConfigureBlock)(id cell, id item, NSIndexPath *indexPath);
typedef UIView *(^ViewForSectionBlock)(id sectionItem, NSInteger section);
typedef CGFloat (^HeightForRowBlock)(id item, NSIndexPath *indexPath);
typedef CGFloat (^HeightForSectionBlock)(id sectionItem, NSInteger section);

typedef void (^OperationForRowBlock)(id item, NSIndexPath *indexPath);
typedef BOOL (^CanOperationRowBlock)(id item, NSIndexPath *indexPath);
typedef void (^CommitEditRowBlock)(id item, UITableViewCellEditingStyle editingStyle, NSIndexPath *indexPath);

@interface VGTArrayDataSources : NSObject

@property (nonatomic, assign) BOOL doNotUseXib; //需要在 setTableView 之前设置
@property (nonatomic, assign) BOOL doNotDeselecteRow;

@property (nonatomic, strong, readonly) NSArray *itemsArray;
@property (nonatomic, strong, readonly) NSMutableArray *sectionItems;
@property (nonatomic,   weak) UITableView *tableView;
@property (nonatomic,   weak) UICollectionView *collectionView;

@property (nonatomic,   copy) OperationForRowBlock didSelectCellBlock;
//section header & footer
@property (nonatomic,   copy) ViewForSectionBlock headerViewForSection;
@property (nonatomic,   copy) ViewForSectionBlock footerViewForSection;
@property (nonatomic,   copy) HeightForRowBlock heightForRow;
@property (nonatomic,   copy) HeightForSectionBlock heightForHeaderInSection;
@property (nonatomic,   copy) HeightForSectionBlock heightForFooterInSection;

@property (nonatomic,   copy) CellConfigureBlock willDisplayCellBlock;
@property (nonatomic,   copy) CellConfigureBlock didEndDisplayCellBlock;

@property (nonatomic, strong) CanOperationRowBlock canEditForRow;
//删除Row数据之前执行
@property (nonatomic, strong) CommitEditRowBlock preCommitEditRow;
//删除Row数据 默认是 [self removeCell:]，如果实现了这个block则覆盖默认行为
@property (nonatomic, strong) CommitEditRowBlock commitEditRow;
//删除Row之后执行
@property (nonatomic, strong) CommitEditRowBlock postCommitEditRow;

@property (nonatomic, strong) UICollectionReusableView * (^reusableViewForSection)(id sectionItem, NSString *kind, NSIndexPath *indexPath);

//Display


//CollectionView layout
@property (nonatomic,   copy) UICollectionViewFlowLayout * (^collectionViewLayout)();
@property (nonatomic,   copy) CGSize (^collectionViewLayoutSize)(id item, UICollectionViewLayout *collectionViewLayout, NSIndexPath *indexPath);
@property (nonatomic,   copy) CGSize (^collectionViewFooterSize)(id sectionItem, UICollectionViewLayout *collectionViewLayout, NSInteger section);
@property (nonatomic,   copy) CGSize (^collectionViewHeaderSize)(id sectionItem, UICollectionViewLayout *collectionViewLayout, NSInteger section);
//自定义Section title属性和子数组属性
@property (nonatomic,   copy) NSDictionary *(^customSectionProperties)();

#define SECTION_CLASS_NAME @"sectionClassItems"
#define SECTION_SUBARRAY_NAME @"sectionSubItems"
#define SECTION_TITLE_NAME @"sectionTitle"

//scroll view
@property (nonatomic,   copy) void(^didScrollBlock)(UIScrollView *scrollView);
@property (nonatomic,   copy) void(^willBeginDraggingBlock)(UIScrollView *scrollView);
@property (nonatomic,   copy) void(^didEndDraggingBlock)(UIScrollView *scrollView, BOOL willDecelerate, NSIndexPath *currentIndexPath);
@property (nonatomic,   copy) void(^didEndDeceleratingBlock)(UIScrollView *scrollView, NSIndexPath *currentIndexPath);
@property (nonatomic,   copy) void(^WillEndDraggingBlock)(UIScrollView *scrollView, CGPoint velocity, CGPoint *targetContentOffset);


//For single section
- (instancetype)initWithItems:(NSArray *)items cellClass:(NSString *)cellClass configureCellBlock:(CellConfigureBlock)configureCellBlock;

//For mutiply sections
- (instancetype)initWithSectionItems:(NSArray *)sectionItems cellClass:(NSString *)cellClass configureCellBlock:(CellConfigureBlock)configureCellBlock;

- (instancetype)initWithModelCellMap:(NSDictionary *)map configureCellBlock:(CellConfigureBlock)configureCellBlock;

- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

- (instancetype)initWithModelCellMap:(NSDictionary *)map sectionItems:(NSArray *)sectionItems configureCellBlock:(CellConfigureBlock)configureCellBlock;

//Item
- (void)reloadWithItems:(NSArray *)items;
- (void)reloadWithItems:(NSArray *)items animated:(BOOL)animated;
- (void)addNewItems:(NSArray *)newItems;
- (void)insertNewItems:(NSArray *)newItems atIndexPath:(NSIndexPath *)indexPath;
- (void)insertNewItems:(NSArray *)newItems atIndex:(NSInteger)index;
- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath;

//Section
- (void)reloadWithSectionItems:(NSArray *)sectionItems;
- (void)reloadWithSectionItems:(NSArray *)sectionItems animated:(BOOL)animated;
- (void)addNewSectionItems:(NSArray *)newSectionItems;
- (void)insertNewSectionItems:(NSArray *)sectionItems atSectionIndex:(NSInteger)sectionIndex;

/**
 *  reload tableview or collectionview sections with animation
 */
- (void)reloadSectionAtIndex:(NSInteger)index;

/**
 *  reload tableview sections with animation
 *
 *  @param animation <#animation description#>
 */
- (void)reloadSectionsWithRowAnimation:(UITableViewRowAnimation)animation;


- (void)scrollToEndWithDelay:(NSTimeInterval)delay animated:(BOOL)animated;


//Empty
- (void)handleEmptyWithMessage:(NSString *)message imageName:(NSString *)imageName;
- (void)handleErrorWithMessage:(NSString *)message imageName:(NSString *)imageName;
@end


@interface ArrayDSDefaultSection : NSObject
@property (nonatomic,   copy) NSString *sectionTitle;
@property (nonatomic, strong) NSMutableArray *sectionItems;
@end
