//
//  CollectionDataSources.h
//  Magazine
//
//  Created by 江文帆 on 15/9/14.
//  Copyright (c) 2015年 江文帆. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^wf_CellConfigureBlock)(id cell, id item, NSIndexPath *indexPath);
typedef UIView *(^wf_ViewForSectionBlock)(id sectionItem, NSInteger section);
typedef CGFloat (^wf_HeightForRowBlock)(id item, NSIndexPath *indexPath);
typedef CGFloat (^wf_HeightForSectionBlock)(id sectionItem, NSInteger section);
typedef void (^wf_OperationForRowBlock)(id item, NSIndexPath *indexPath);
typedef BOOL (^wf_CanOperationRowBlock)(id item, NSIndexPath *indexPath);
typedef void (^wf_CommitEditRowBlock)(id item, UITableViewCellEditingStyle editingStyle, NSIndexPath *indexPath);
typedef UICollectionReusableView *(^wf_ReusebleViewBlock)(id sectionItem, NSString *kind, NSIndexPath *indexPath);
typedef UICollectionViewFlowLayout *(^wf_FlowLayoutBlock)();
typedef CGSize (^wf_FlowLayoutSectionSizeBlock)(id sectionItem, UICollectionViewLayout *collectionViewLayout, NSInteger section);
typedef CGSize (^wf_FlowLayoutSizeBlock)(id sectionItem, UICollectionViewLayout *collectionViewLayout, NSIndexPath *indexPath);

@protocol VGTCellConfig <NSObject>
@required;
- (void)configCellWithItem:(id)item;

@optional;
- (void)setupCell;
@end

@class VGTEmpty;

@interface WFDataSource : NSObject
@property (nonatomic,   copy) wf_OperationForRowBlock didSelectCellBlock;
@property (nonatomic,   copy) wf_ViewForSectionBlock headerViewForSection;
@property (nonatomic,   copy) wf_ViewForSectionBlock footerViewForSection;
@property (nonatomic,   copy) wf_HeightForRowBlock heightForRow;
@property (nonatomic,   copy) wf_HeightForSectionBlock heightForHeaderInSection;
@property (nonatomic,   copy) wf_HeightForSectionBlock heightForFooterInSection;

@property (nonatomic,   copy) wf_CellConfigureBlock willDisplayCellBlock;
@property (nonatomic,   copy) wf_CellConfigureBlock didEndDisplayCellBlock;
@property (nonatomic, strong) wf_CanOperationRowBlock canEditForRow;

@property (nonatomic, strong) wf_CommitEditRowBlock preCommitEditRow;
@property (nonatomic, strong) wf_CommitEditRowBlock commitEditRow;
@property (nonatomic, strong) wf_CommitEditRowBlock postCommitEditRow;

@property (nonatomic, strong) wf_ReusebleViewBlock reusableViewForSection;
@property (nonatomic,   copy) wf_FlowLayoutBlock collectionViewLayout;
@property (nonatomic,   copy) wf_FlowLayoutSizeBlock collectionViewLayoutSize;
@property (nonatomic,   copy) wf_FlowLayoutSectionSizeBlock collectionViewFooterSize;
@property (nonatomic,   copy) wf_FlowLayoutSectionSizeBlock collectionViewHeaderSize;

@property (nonatomic,   copy) void(^didScrollBlock)(UIScrollView *scrollView);
@property (nonatomic,   copy) void(^willBeginDraggingBlock)(UIScrollView *scrollView);
@property (nonatomic,   copy) void(^didEndDraggingBlock)(UIScrollView *scrollView, BOOL willDecelerate, NSIndexPath *currentIndexPath);
@property (nonatomic,   copy) void(^didEndDeceleratingBlock)(UIScrollView *scrollView, NSIndexPath *currentIndexPath);
@property (nonatomic,   copy) void(^WillEndDraggingBlock)(UIScrollView *scrollView, CGPoint velocity, CGPoint *targetContentOffset);
@property (nonatomic,   copy) void(^didEndScrollingAnimationBlock)(UIScrollView *scrollView, NSIndexPath *currentIndexPath);

@property (nonatomic, assign) BOOL doNotDeselecteRow;

@property (nonatomic, strong, readonly) NSArray *items;

@property (nonatomic, strong, readonly) NSMutableArray *sectionItems;

@property (nonatomic,   weak) UITableView *tableView;

@property (nonatomic,   weak) UICollectionView *collectionView;



//init
- (instancetype)initWithModelCellMap:(NSDictionary *)map cellConfigBlock:(wf_CellConfigureBlock)block;


//Reload
- (void)reloadWithItems:(NSArray *)items;

- (void)reloadWithItems:(NSArray *)items animated:(BOOL)animated;

- (void)reloadWithSectionItems:(NSArray *)sectionItems;

- (void)reloadWithSectionItems:(NSArray *)sectionItems animated:(BOOL)animated;

- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadSectionAtIndex:(NSInteger)index;

- (void)reloadSectionAtIndex:(NSInteger)index withRowAnimation:(UITableViewRowAnimation)animation;

- (void)reloadSectionsWithRowAnimation:(UITableViewRowAnimation)animation;


//Insert
- (void)addNewItems:(NSArray *)newItems;

- (void)insertNewItems:(NSArray *)newItems atIndex:(NSInteger)index;

- (void)insertNewItems:(NSArray *)newItems atIndexPath:(NSIndexPath *)indexPath;

- (void)addNewSectionItems:(NSArray *)newSectionItems;

- (void)insertNewSectionItems:(NSArray *)sectionItems atIndex:(NSInteger)index;

- (void)insertNewSectionItems:(NSArray *)sectionItems atIndexPath:(NSIndexPath *)indexPath;


//Remove
- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath animation:(UITableViewRowAnimation)animation;

- (void)removeCellWithItem:(id)item;

//Helper
- (void)scrollToEndWithDelay:(NSTimeInterval)delay animated:(BOOL)animated;

- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

//Empty
- (void)handleEmptyWithMessage:(NSString *)message imageName:(NSString *)imageName;
- (void)handleEmptyWithTitle:(NSString *)title message:(NSString *)message imageName:(NSString *)imageName action:(dispatch_block_t)action;
- (void)handleEmptyWithEmptyObject:(VGTEmpty *)emptyObject;
@end


@interface WFDataSourceSection : NSObject
@property (nonatomic,   copy) NSString *sectionTitle;
@property (nonatomic, strong) NSMutableArray *sectionItems;
@end


#pragma mark - Empty
@interface VGTEmpty : NSObject
@property (nonatomic,   copy) NSString *title;
@property (nonatomic,   copy) NSString *message;
@property (nonatomic,   copy) NSString *imageName;
@property (nonatomic,   copy) dispatch_block_t action;
@property (nonatomic,   copy) NSString *actionTitle;

@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *messageColor;
@property (nonatomic, strong) UIView *customView;

@property (nonatomic, assign) CGFloat cellInsetTop;
@end

@interface VGTEmptyCell : UITableViewCell <VGTCellConfig>
@property (nonatomic, strong) UIColor *titleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *messageColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *actionButtonColor UI_APPEARANCE_SELECTOR;
@property (nonatomic,   copy) NSString *emptyImageName UI_APPEARANCE_SELECTOR;
@end
