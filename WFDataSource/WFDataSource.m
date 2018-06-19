//
//  CollectionDataSources.m
//  WFDataSource
//
//  Created by 江文帆 on 15/9/14.
//  Copyright (c) 2015年 江文帆. All rights reserved.
//

#import "WFDataSource.h"

#define SECTION_CLASS_NAME @"sectionClassItems"
#define SECTION_SUBARRAY_NAME @"sectionSubItems"
#define SECTION_TITLE_NAME @"sectionTitle"

@interface WFDataSource() <UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableDictionary *modelCellMap;

@property (nonatomic,   copy) NSDictionary *(^customSectionProperties)(void);

@property (nonatomic, strong) NSMutableDictionary *heightAtIndexPath;
@end

@implementation WFDataSource

@synthesize sectionItems = _sectionItems;

- (id)init
{
    return nil;
}

#pragma mark - Init

- (instancetype)initWithModelCellMap:(NSDictionary *)map cellConfigBlock:(wf_CellConfigureBlock)block
{
    return [self initWithModelCellMap:map items:nil cellConfigBlock:block];
}

- (instancetype)initWithModelCellMap:(NSDictionary *)map items:(NSArray *)items cellConfigBlock:(wf_CellConfigureBlock)block
{
    WFDataSourceSection *section = [WFDataSourceSection new];
    section.sectionTitle = nil;
    section.sectionItems = [items mutableCopy];
    return [self initWithModelCellMap:map sectionItems:@[section] cellConfigBlock:block];
}

- (instancetype)initWithModelCellMap:(NSDictionary *)map sectionItems:(NSArray *)sectionItems cellConfigBlock:(wf_CellConfigureBlock)block
{
    self = [super init];
    if (self) {
        [self.sectionItems removeAllObjects];
        [self.sectionItems addObjectsFromArray:sectionItems];
        [self.modelCellMap removeAllObjects];
        
        [self.modelCellMap addEntriesFromDictionary:map];
        self.cellConfigBlock = [block copy];
        self.heightAtIndexPath = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addCellMapWithModel:(NSString *)modelName cell:(NSString *)cellName identifier:(NSString *)identifier
{
    [self.modelCellMap setObject:[NSString stringWithFormat:@"%@-%@",cellName, identifier] forKey:modelName];
}


#pragma mark - Reload

- (void)reloadWithItems:(NSArray *)items
{
    [self reloadWithItems:items animated:NO];
}

- (void)reloadWithItems:(NSArray *)items animated:(BOOL)animated
{
    WFDataSourceSection *section = [WFDataSourceSection new];
    section.sectionTitle = nil;
    section.sectionItems = [NSMutableArray arrayWithArray:items];
    [self reloadWithSectionItems:@[section] animated:animated];
}

- (void)reloadWithSectionItems:(NSArray *)sectionItems
{
    [self reloadWithSectionItems:sectionItems animated:NO];
}

- (void)reloadWithSectionItems:(NSArray *)sectionItems animated:(BOOL)animated
{
    [self.sectionItems removeAllObjects];
    [self.sectionItems addObjectsFromArray:sectionItems];
    
    if (!animated) {
        [self.tableView reloadData];
        [self.collectionView reloadData];
    }else {
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        [sectionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [indexSet addIndex:idx];
        }];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        [self.collectionView reloadSections:indexSet];
    }
}

- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)reloadSectionAtIndex:(NSInteger)index
{
    [self reloadSectionAtIndex:index withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)reloadSectionAtIndex:(NSInteger)index withRowAnimation:(UITableViewRowAnimation)animation
{
    NSRange range = NSMakeRange(index, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:sectionToReload];
    } completion:nil];
    [self.tableView reloadSections:sectionToReload withRowAnimation:animation];
}

- (void)reloadSectionsWithRowAnimation:(UITableViewRowAnimation)animation
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSInteger count = self.sectionItems.count == 0?1:self.sectionItems.count;
    for (NSInteger startIndex = 0; startIndex < count; startIndex ++) {
        [indexSet addIndex:startIndex];
    }
    [self.tableView reloadSections:indexSet withRowAnimation:animation];
    [self.collectionView reloadSections:indexSet];
}





#pragma mark - Insert

- (void)addNewItems:(NSArray *)newItems
{
    if (!self.sectionItems.count) {
        [self reloadWithItems:newItems];
    }else {
        WFDataSourceSection *secion = self.sectionItems.firstObject;
        [self insertNewItems:newItems atIndexPath:[NSIndexPath indexPathForItem:secion.sectionItems.count inSection:0]];
    }
}

- (void)insertNewItems:(NSArray *)newItems atIndex:(NSInteger)index
{
    [self insertNewItems:newItems atIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (void)insertNewItems:(NSArray *)newItems atIndexPath:(NSIndexPath *)indexPath
{
    if (self.items.count == 1 && [self.items.firstObject isKindOfClass:[WFDataSourceEmpty class]]) {
        [self reloadWithItems:newItems];
        return;
    }
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSInteger startIndex = indexPath.item; startIndex < indexPath.item + newItems.count; startIndex ++) {
        [indexSet addIndex:startIndex];
    }
    NSMutableArray *sectionitem = [self.sectionItems objectAtIndex:indexPath.section];
    [((NSMutableArray *)[sectionitem mutableArrayValueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] ) insertObjects:newItems atIndexes:indexSet];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:newItems.count];
    [newItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPathToAdd = [NSIndexPath indexPathForItem:indexPath.item + idx inSection:indexPath.section];
        [indexPaths addObject:indexPathToAdd];
    }];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    } completion:nil];
}

- (void)addNewSectionItems:(NSArray *)newSectionItems
{
    [self insertNewSectionItems:newSectionItems atIndex:self.sectionItems.count];
}

- (void)insertNewSectionItems:(NSArray *)sectionItems atIndex:(NSInteger)index
{
    [self insertNewSectionItems:sectionItems atIndexPath:[NSIndexPath indexPathForItem:0 inSection:index]];
}

- (void)insertNewSectionItems:(NSArray *)sectionItems atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *sectionDatasM = [NSMutableArray arrayWithArray:sectionItems];
    if (indexPath.section > 0) {
        /*处理重复情况*/
        id lastSectionItem = [self.sectionItems objectAtIndex:indexPath.section - 1];
        id newFirstSectionItem = sectionItems.firstObject;
        NSString *title = [self sectionPropertiesMap][SECTION_TITLE_NAME];
        if ([[lastSectionItem valueForKey:title] isEqual:[newFirstSectionItem valueForKey:title]]) {
            [self insertNewItems:[newFirstSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] atIndexPath:[NSIndexPath indexPathForItem:[[lastSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] count] inSection:indexPath.section-1]];
            [sectionDatasM removeObject:newFirstSectionItem];
        }
        /***********/
    }
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSInteger startIndex = indexPath.section; startIndex < indexPath.section + sectionDatasM.count; startIndex ++) {
        [indexSet addIndex:startIndex];
    }
    [self.tableView beginUpdates];
    [self.sectionItems insertObjects:sectionDatasM atIndexes:indexSet];
    [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertSections:indexSet];
    } completion:nil];
}

- (NSDictionary *)sectionPropertiesMap
{
    if (self.customSectionProperties) {
        return self.customSectionProperties();
    }else {
        return @{SECTION_CLASS_NAME:@"WFDataSourceSection", SECTION_TITLE_NAME:@"sectionTitle",SECTION_SUBARRAY_NAME:@"sectionItems"};
    }
}



#pragma mark - Remove (TableView)

- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeCellAtIndexPath:indexPath animation:UITableViewRowAnimationFade];
}

- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath animation:(UITableViewRowAnimation)animation
{
    if (indexPath == nil) {
        return;
    }
    id sectionItem = [self.sectionItems objectAtIndex:indexPath.section];
    NSMutableArray *sectionSubArray = [sectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
    id item = sectionSubArray[indexPath.row];
    [sectionSubArray removeObject:item];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
    [self.tableView endUpdates];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
}

- (void)removeCellWithItem:(id)item
{
    __block NSIndexPath *indexPath;
    [self.sectionItems enumerateObjectsUsingBlock:^(id sectionItem, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *sectionSubArray = [sectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
        NSInteger index = [sectionSubArray indexOfObject:item];
        if (index != NSNotFound) {
            indexPath = [NSIndexPath indexPathForItem:index inSection:idx];
            *stop = YES;
        }
    }];
    if (indexPath) {
        [self removeCellAtIndexPath:indexPath];
    }
}





#pragma mark - UITableView Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionItem = [self.sectionItems objectAtIndex:section];
    NSMutableArray *sectionSubArray = [sectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
    return sectionSubArray.count;
}

#pragma mark  UITableView Cell

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForListView:tableView indexPath:indexPath];
}

- (id)cellForListView:(UIView *)listView indexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    
    __block NSString *cellIdentifier;
    __block NSString *cellClassName;
    if (self.modelCellMap.count) {
        if ([item isKindOfClass:[NSString class]] ||
            [item isKindOfClass:[NSDictionary class]]
            ) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
                Class modelClass = NSClassFromString(key);
                if ([item isKindOfClass:modelClass]) {
                    cellClassName = [obj componentsSeparatedByString:@"-"].firstObject;
                    cellIdentifier = [obj componentsSeparatedByString:@"-"].lastObject;
                    *stop = YES;
                }
            }];
        }else {
            NSString *value = [self.modelCellMap objectForKey:NSStringFromClass([item class])];
            cellClassName = [value componentsSeparatedByString:@"-"].firstObject;
            cellIdentifier = [value componentsSeparatedByString:@"-"].lastObject;
        }
        if (!cellIdentifier) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
                Class modelClass = NSClassFromString(key);
                if ([item isKindOfClass:modelClass]) {
                    cellClassName = [obj componentsSeparatedByString:@"-"].firstObject;
                    cellIdentifier = [obj componentsSeparatedByString:@"-"].lastObject;
                    *stop = YES;
                }
            }];
            if (!cellIdentifier) {
                NSString *classString = NSStringFromClass([item class]);
                @throw [NSException exceptionWithName:@"cellIdentifier 异常" reason:classString userInfo:self.modelCellMap];
            }
        }
    }else {
        cellIdentifier = @"UITableViewCell";
    }
    
    id cell;
    if ([listView isKindOfClass:[UITableView class]]) {
        if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
            [(UITableView *)listView registerClass:[WFDataSourceEmptyCell class] forCellReuseIdentifier:@"WFDataSourceEmptyCell"];
        }
        cell = [(UITableView *)listView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    }else {
        cell = [(UICollectionView *)listView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
        if ([listView isKindOfClass:[UITableView class]]) {
            WFDataSourceEmptyCell *tableViewCell = (WFDataSourceEmptyCell *)cell;
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [tableViewCell setSeparatorInset:UIEdgeInsetsMake(0, _tableView.frame.size.width, 0, 0)];
            [tableViewCell setLayoutMargins:UIEdgeInsetsMake(0, _tableView.frame.size.width, 0, 0)];
            [tableViewCell setPreservesSuperviewLayoutMargins:NO];
            [tableViewCell configWithItem:item];
            return tableViewCell;
        }else {
            WFDataSourceEmptyCollectionCell *collectionCell = (WFDataSourceEmptyCollectionCell *)cell;
            [collectionCell setLayoutMargins:UIEdgeInsetsMake(0, _tableView.frame.size.width, 0, 0)];
            [collectionCell setPreservesSuperviewLayoutMargins:NO];
            [collectionCell configWithItem:item];
            return collectionCell;
        }
    }else {
        self.cellConfigBlock(cell, item, indexPath);
        return cell;
    }
}

#pragma mark  UITableView Height

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
        return self.tableView.bounds.size.height - [item cellInsetTop];// - self.tableView.contentInset.top;
    }else {
        if (self.heightForRow) {
            return self.heightForRow(item, indexPath);
        }
        return self.tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.heightForHeaderInSection) {
        return self.heightForHeaderInSection(self.sectionItems[section], section);
    }
    
    if (self.headerViewForSection) {
        UIView *headerView = self.headerViewForSection(self.sectionItems[section], section);
        CGFloat height = CGRectGetHeight(headerView.frame);
        return height;
    }else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.heightForFooterInSection) {
        return self.heightForFooterInSection(self.sectionItems[section], section);
    }
    
    if (self.footerViewForSection) {
        UIView *headerView = self.footerViewForSection(self.sectionItems[section], section);
        CGFloat height = CGRectGetHeight(headerView.frame);
        return height;
    }else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *height = [self.heightAtIndexPath objectForKey:indexPath];
    if(height) {
        return height.floatValue;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *height = @(cell.frame.size.height);
    [self.heightAtIndexPath setObject:height forKey:indexPath];
    if (self.willDisplayCellBlock) {
        id item = [self itemAtIndexPath:indexPath];
        self.willDisplayCellBlock(cell, item, indexPath);
    }
}
    
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (self.didEndDisplayCellBlock) {
        id item = [self itemAtIndexPath:indexPath];
        if (item) {
            self.didEndDisplayCellBlock(cell, item, indexPath);
        }
    }
}

#pragma mark  UITableView Section Header/Footer View

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.headerViewForSection) {
        return self.headerViewForSection(self.sectionItems[section], section);
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.footerViewForSection) {
        return self.footerViewForSection(self.sectionItems[section], section);
    }
    return nil;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.doNotDeselecteRow) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    id item = [self itemAtIndexPath:indexPath];
    
    if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
        
    }else {
        if (self.didSelectCellBlock) {
            self.didSelectCellBlock(item, indexPath);
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id item = [self itemAtIndexPath:indexPath];
        if (self.preCommitEditRow) {
            self.preCommitEditRow(item, editingStyle, indexPath);
        }
        if (self.commitEditRow) {
            self.commitEditRow(item, editingStyle, indexPath);
        }else{
            [self removeCellAtIndexPath:indexPath];
        }
        if (self.postCommitEditRow) {
            self.postCommitEditRow(item, editingStyle, indexPath);
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.canEditForRow) {
        id item = [self itemAtIndexPath:indexPath];
        return self.canEditForRow(item, indexPath);
    }
    return self.tableView.editing;
}







#pragma mark - UICollection Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.sectionItems.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id sectionItem = [self.sectionItems objectAtIndex:section];
    NSMutableArray *sectionSubArray = [sectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
    return sectionSubArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForListView:collectionView indexPath:indexPath];
}


#pragma mark - UICollection Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
        
    }else {
        if (self.didSelectCellBlock) {
            self.didSelectCellBlock(item, indexPath);
        }
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (self.reusableViewForSection) {
        id sectionItem = [self.sectionItems objectAtIndex:indexPath.section];
        id view = self.reusableViewForSection(sectionItem, kind, indexPath);
        return view;
    }else {
        return nil;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout heightForHeaderInSection:(NSInteger)section
{
    if (self.sectionItems.count) {
        id sectionItem = self.sectionItems[section];
        if (self.collectionViewHeaderSize) {
            return self.collectionViewHeaderSize(sectionItem, collectionViewLayout, section).height;
        }
        return 0;
    }
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout heightForFooterInSection:(NSInteger)section
{
    if (self.sectionItems.count) {
        id sectionItem = self.sectionItems[section];
        if (self.collectionViewFooterSize) {
            return self.collectionViewFooterSize(sectionItem, collectionViewLayout, section).height;
        }
        return 0;
    }
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.willDisplayCellBlock) {
        id item = [self itemAtIndexPath:indexPath];
        self.willDisplayCellBlock(cell, item, indexPath);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.didEndDisplayCellBlock) {
        id item = [self itemAtIndexPath:indexPath];
        if (item) {
            self.didEndDisplayCellBlock(cell, item, indexPath);
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    id item = [self itemAtIndexPath:indexPath];
    if ([item isKindOfClass:[WFDataSourceEmpty class]]) {
        return self.collectionView.bounds.size;
    }else {
        if (self.collectionViewLayoutSize) {
            return self.collectionViewLayoutSize(item, collectionViewLayout, indexPath);
        }else if ([self.collectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]] && self.collectionView.collectionViewLayout) {
            return ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize;
        }else {
            if (self.collectionViewLayout) {
                return self.collectionViewLayout().itemSize;
            }else {
                return CGSizeZero;
            }
        }
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    WFDataSourceSection *section_item = self.sectionItems[section];
    if (self.collectionSectionInset) {
        return self.collectionSectionInset(section_item, section);
    }else if ([self.collectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]] && self.collectionView.collectionViewLayout) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        return flowLayout.sectionInset;
    }else {
        return UIEdgeInsetsZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.sectionItems.count) {
        id sectionItem = self.sectionItems[section];
        if (self.collectionViewHeaderSize) {
            return self.collectionViewHeaderSize(sectionItem, collectionViewLayout, section);
        }
        return CGSizeZero;
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.sectionItems.count) {
        id sectionItem = self.sectionItems[section];
        if (self.collectionViewFooterSize) {
            return self.collectionViewFooterSize(sectionItem, collectionViewLayout, section);
        }
        return CGSizeZero;
    }
    return CGSizeZero;
}


#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.didScrollBlock) {
        self.didScrollBlock(scrollView);
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.willBeginDraggingBlock) {
        self.willBeginDraggingBlock(scrollView);
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        NSIndexPath *currentIndexPath;
        if (self.collectionView) {
            currentIndexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];
        }else {
            currentIndexPath = [[self.tableView indexPathsForVisibleRows] firstObject];
        }
        if (self.didEndDraggingBlock) {
            self.didEndDraggingBlock(scrollView, decelerate, currentIndexPath);
        }
    }else {
        if (self.didEndDraggingBlock) {
            self.didEndDraggingBlock(scrollView, decelerate, nil);
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSIndexPath *currentIndexPath;
    if (self.collectionView) {
        currentIndexPath = [[self.collectionView indexPathsForVisibleItems]firstObject];
    }else {
        currentIndexPath = [[self.tableView indexPathsForVisibleRows]firstObject];
    }
    if (self.didEndScrollingAnimationBlock) {
        self.didEndScrollingAnimationBlock(scrollView, currentIndexPath);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSIndexPath *currentIndexPath;
    if (self.collectionView) {
        currentIndexPath = [[self.collectionView indexPathsForVisibleItems]firstObject];
    }else {
        currentIndexPath = [[self.tableView indexPathsForVisibleRows]firstObject];
    }
    if (self.didEndDeceleratingBlock) {
        self.didEndDeceleratingBlock(scrollView, currentIndexPath);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.WillEndDraggingBlock) {
        self.WillEndDraggingBlock(scrollView, velocity, targetContentOffset);
    }
}





#pragma mark - Helper

- (void)scrollToEndWithDelay:(NSTimeInterval)delay animated:(BOOL)animated
{
    if (self.items.count||self.sectionItems.count) {
        NSIndexPath *indexPath;
        if (self.sectionItems.count) {
            id lastSectionItem = [self.sectionItems objectAtIndex:self.sectionItems.count-1];
            NSMutableArray *sectionSubArray = [lastSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
            indexPath = [NSIndexPath indexPathForItem:sectionSubArray.count-1 inSection:self.sectionItems.count-1];
        }else {
            indexPath = [NSIndexPath indexPathForItem:self.items.count-1 inSection:0];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
        });
    }
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sectionItems.count) {
        id sectionItem = [self.sectionItems objectAtIndex:indexPath.section];
        NSMutableArray *sectionSubArray = [sectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
        if (indexPath.row < sectionSubArray.count) {
            return sectionSubArray[indexPath.row];
        }else {
            return nil;
        }
    }else {
        return nil;
    }
}

#pragma mark -  lazy

- (NSMutableDictionary *)modelCellMap
{
    if (_modelCellMap == nil) {
        _modelCellMap = [[NSMutableDictionary alloc]init];
    }
    return _modelCellMap;
}

- (NSArray *)items
{
    return [[_sectionItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] copy];
}

- (NSMutableArray *)sectionItems
{
    if (_sectionItems == nil) {
        _sectionItems = [[NSMutableArray alloc]init];
    }
    return _sectionItems;
}


- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    tableView.dataSource = self;
    tableView.delegate = self;
    NSDictionary *empty = @{@"WFDataSourceEmpty": @"WFDataSourceEmptyCell"};
    [self.modelCellMap addEntriesFromDictionary:empty];
    if (self.modelCellMap.count) {
        [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *obj, BOOL * _Nonnull stop) {
            NSString *cellIdentifier;
            NSString *cellClassName;
            cellClassName = [obj componentsSeparatedByString:@"-"].firstObject;
            cellIdentifier = [obj componentsSeparatedByString:@"-"].lastObject;
            NSString *nibPath = [self.resourceBundle?:[NSBundle mainBundle] pathForResource:cellClassName ofType:@"nib"];
            if (nibPath && [[NSFileManager defaultManager] fileExistsAtPath:nibPath]) {
                [tableView registerNib:[UINib nibWithNibName:cellClassName bundle:self.resourceBundle] forCellReuseIdentifier:cellIdentifier];
            }else {
                Class cellClass = NSClassFromString(cellClassName);
                if (cellClass) {
                    [tableView registerClass:cellClass forCellReuseIdentifier:cellIdentifier];
                }
            }
        }];
    }
    [tableView reloadData];
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    NSDictionary *empty = @{@"WFDataSourceEmpty": @"WFDataSourceEmptyCollectionCell"};
    [self.modelCellMap addEntriesFromDictionary:empty];
    if (self.modelCellMap.count) {
        [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *obj, BOOL * _Nonnull stop) {
            NSString *cellIdentifier;
            NSString *cellClassName;
            cellClassName = [obj componentsSeparatedByString:@"-"].firstObject;
            cellIdentifier = [obj componentsSeparatedByString:@"-"].lastObject;
            NSString *nibPath = [self.resourceBundle?:[NSBundle mainBundle] pathForResource:cellClassName ofType:@"nib"];
            if (nibPath && [[NSFileManager defaultManager] fileExistsAtPath:nibPath]) {
                [collectionView registerNib:[UINib nibWithNibName:cellClassName bundle:self.resourceBundle] forCellWithReuseIdentifier:cellIdentifier];
            }else {
                Class cellClass = NSClassFromString(cellClassName);
                if (cellClass) {
                    [collectionView registerClass:cellClass forCellWithReuseIdentifier:cellIdentifier];
                }
            }
        }];
    }
    [collectionView reloadData];
}

#pragma mark - Empty
- (void)handleEmptyWithMessage:(NSString *)message imageName:(NSString *)imageName
{
    [self handleEmptyWithTitle:nil message:message imageName:imageName action:nil];
}

- (void)handleEmptyWithEmptyObject:(WFDataSourceEmpty *)emptyObject
{
    [self reloadWithItems:@[emptyObject]];
}

- (void)handleEmptyWithTitle:(NSString *)title message:(NSString *)message imageName:(NSString *)imageName action:(dispatch_block_t)action
{
    WFDataSourceEmpty *emptyObject = [WFDataSourceEmpty new];
    emptyObject.title = title;
    emptyObject.action = action;
    emptyObject.message = message;
    emptyObject.imageName = imageName;
    [self.tableView registerClass:[WFDataSourceEmptyCell class] forCellReuseIdentifier:@"WFDataSourceEmptyCell"];
    [self reloadWithItems:@[emptyObject]];
}
@end


@implementation WFDataSourceSection
- (NSMutableArray *)sectionItems
{
    if (_sectionItems == nil) {
        _sectionItems = [NSMutableArray array];
    }
    return _sectionItems;
}
@end


@interface WFDataSourceEmpty ()

@end

@implementation WFDataSourceEmpty

@end

@interface WFDataSourceEmptyCell()

@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIImageView *placeHolderView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) WFDataSourceEmpty *item;
@property (nonatomic, strong) UIView *customView;
@end

@implementation WFDataSourceEmptyCell
+ (void)load
{
    [super load];
    [WFDataSourceEmptyCell appearance].titleColor = [UIColor blackColor];
    [WFDataSourceEmptyCell appearance].messageColor = [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1];
    [WFDataSourceEmptyCell appearance].actionButtonColor = [UIColor whiteColor];
    [WFDataSourceEmptyCell appearance].actionButtonBgColor = [UIColor blueColor];
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    self.titleLable = ({
        UILabel *titlelabel = [UILabel new];
        titlelabel.textColor = [WFDataSourceEmptyCell appearance].titleColor;
        titlelabel.textAlignment = NSTextAlignmentCenter;
        titlelabel.font = [UIFont boldSystemFontOfSize:20];
        titlelabel;
    });
    [self.contentView addSubview:self.titleLable];
    
    self.messageLabel = ({
        UILabel *messageLabel = [UILabel new];
        messageLabel.textColor = [WFDataSourceEmptyCell appearance].messageColor;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:15];
        messageLabel.numberOfLines = 3;
        messageLabel;
    });
    [self.contentView addSubview:self.messageLabel];
    
    self.placeHolderView = ({
        UIImageView *placeHolderView = [UIImageView new];
        placeHolderView.contentMode = UIViewContentModeCenter;
        placeHolderView;
    });
    [self.contentView addSubview:self.placeHolderView];
    
    self.actionButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"刷新重试" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [WFDataSourceEmptyCell appearance].actionButtonColor;
        button.layer.cornerRadius = 4;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(onTapAction:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.actionButton];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.placeHolderView.bounds = CGRectMake(0, 0, self.placeHolderView.image.size.width, self.placeHolderView.image.size.height);
    self.placeHolderView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/3);
    
    if (self.item.title) {
        self.titleLable.frame = CGRectMake(0, 0, self.bounds.size.width * 0.7, 20);
        self.titleLable.center = CGPointMake(CGRectGetMidX(self.placeHolderView.frame), CGRectGetMaxY(self.placeHolderView.frame) + 40);
        self.messageLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLable.frame) + 10, self.bounds.size.width * 0.7, 40);
        self.messageLabel.center = CGPointMake(CGRectGetMidX(self.titleLable.frame), self.messageLabel.center.y);
    }else {
        self.messageLabel.frame = CGRectMake(0, 0, self.bounds.size.width * 0.7, 40);
        self.messageLabel.center = CGPointMake(CGRectGetMidX(self.placeHolderView.frame), CGRectGetMaxY(self.placeHolderView.frame) + 70);
    }
    self.actionButton.frame = CGRectMake(CGRectGetMinX(self.messageLabel.frame), CGRectGetMaxY(self.messageLabel.frame) + 10, 80, 40);
    self.actionButton.center = CGPointMake(CGRectGetMidX(self.titleLable.frame), self.actionButton.center.y);
}

- (void)configWithItem:(WFDataSourceEmpty *)item
{
    _item = item;
    self.titleLable.text = item.title;
    self.titleLable.hidden = !item.title;
    self.actionButton.hidden = !item.actionTitle;
    
    [self.actionButton setTitle:item.actionTitle?:@"刷新重试" forState:UIControlStateNormal];
    [self.actionButton setTitleColor:item.actionButtonColor?:[WFDataSourceEmptyCell appearance].actionButtonColor forState:UIControlStateNormal];
    self.actionButton.backgroundColor = item.actionButtonBgColor?:[WFDataSourceEmptyCell appearance].actionButtonBgColor;
    
    if (item.titleColor) {
        self.titleLable.textColor = item.titleColor;
    }else {
        self.titleLable.textColor = [WFDataSourceEmptyCell appearance].titleColor;
    }
    
    if (item.messageColor) {
        self.messageLabel.textColor = item.messageColor;
    }else {
        self.messageLabel.textColor = [WFDataSourceEmptyCell appearance].messageColor;
    }
    
    if (item.message) {
        self.messageLabel.text = item.message;
    }else {
        self.messageLabel.text = @"这里什么都没有哦";
    }
    
    self.placeHolderView.image = [UIImage imageNamed:item.imageName?:self.emptyImageName];
    
    [self setupCustomViewWithItem:item];
}

- (void)setupCustomViewWithItem:(WFDataSourceEmpty *)empty
{
    self.customView = empty.customView;
    empty.customView.frame = self.contentView.bounds;
    [empty.customView removeFromSuperview];
    empty.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:empty.customView];
}

- (void)onTapAction:(UIButton *)sender
{
    if (self.item.action) {
        self.item.action();
    }
}
@end



@interface WFDataSourceEmptyCollectionCell()

@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIImageView *placeHolderView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) WFDataSourceEmpty *item;
@property (nonatomic, strong) UIView *customView;
@end

@implementation WFDataSourceEmptyCollectionCell
+ (void)load
{
    [super load];
    [WFDataSourceEmptyCell appearance].titleColor = [UIColor blackColor];
    [WFDataSourceEmptyCell appearance].messageColor = [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1];
    [WFDataSourceEmptyCell appearance].actionButtonColor = [UIColor whiteColor];
    [WFDataSourceEmptyCell appearance].actionButtonBgColor = [UIColor blueColor];
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    self.titleLable = ({
        UILabel *titlelabel = [UILabel new];
        titlelabel.textColor = [WFDataSourceEmptyCell appearance].titleColor;
        titlelabel.textAlignment = NSTextAlignmentCenter;
        titlelabel.font = [UIFont boldSystemFontOfSize:20];
        titlelabel;
    });
    [self.contentView addSubview:self.titleLable];
    
    self.messageLabel = ({
        UILabel *messageLabel = [UILabel new];
        messageLabel.textColor = [WFDataSourceEmptyCell appearance].messageColor;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:15];
        messageLabel.numberOfLines = 3;
        messageLabel;
    });
    [self.contentView addSubview:self.messageLabel];
    
    self.placeHolderView = ({
        UIImageView *placeHolderView = [UIImageView new];
        placeHolderView.contentMode = UIViewContentModeCenter;
        placeHolderView;
    });
    [self.contentView addSubview:self.placeHolderView];
    
    self.actionButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"刷新重试" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        button.layer.cornerRadius = 4;
        button.layer.masksToBounds = YES;
        button.backgroundColor = [WFDataSourceEmptyCollectionCell appearance].actionButtonColor;
        [button setTitleColor:[WFDataSourceEmptyCollectionCell appearance].actionButtonColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onTapAction:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.actionButton];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.placeHolderView.bounds = CGRectMake(0, 0, self.placeHolderView.image.size.width, self.placeHolderView.image.size.height);
    self.placeHolderView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/3);
    
    if (self.item.title) {
        self.titleLable.frame = CGRectMake(0, 0, self.bounds.size.width * 0.7, 20);
        self.titleLable.center = CGPointMake(CGRectGetMidX(self.placeHolderView.frame), CGRectGetMaxY(self.placeHolderView.frame) + 40);
        self.messageLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLable.frame) + 10, self.bounds.size.width * 0.7, 40);
        self.messageLabel.center = CGPointMake(CGRectGetMidX(self.titleLable.frame), self.messageLabel.center.y);
    }else {
        self.messageLabel.frame = CGRectMake(0, 0, self.bounds.size.width * 0.7, 40);
        self.messageLabel.center = CGPointMake(CGRectGetMidX(self.placeHolderView.frame), CGRectGetMaxY(self.placeHolderView.frame) + 70);
    }
    self.actionButton.frame = CGRectMake(CGRectGetMinX(self.messageLabel.frame), CGRectGetMaxY(self.messageLabel.frame) + 10, self.item.actionButtonWidth?:self.messageLabel.frame.size.width, self.item.actionButtonHeight?:60);
    self.actionButton.center = CGPointMake(CGRectGetMidX(self.messageLabel.frame), self.actionButton.center.y);
}

- (void)configWithItem:(WFDataSourceEmpty *)item
{
    _item = item;
    self.titleLable.text = item.title;
    self.titleLable.hidden = !item.title;
    self.actionButton.hidden = !item.action;
    
    if (item.titleColor) {
        self.titleLable.textColor = item.titleColor;
    }else {
        self.titleLable.textColor = [WFDataSourceEmptyCell appearance].titleColor;
    }
    
    if (item.messageColor) {
        self.messageLabel.textColor = item.messageColor;
    }else {
        self.messageLabel.textColor = [WFDataSourceEmptyCell appearance].messageColor;
    }
    
    if (item.message) {
        self.messageLabel.text = item.message;
    }else {
        self.messageLabel.text = @"这里什么都没有哦";
    }
    
    self.placeHolderView.image = [UIImage imageNamed:item.imageName?:self.emptyImageName];

    self.actionButton.backgroundColor = item.actionButtonBgColor;
    [self.actionButton setTitleColor:item.actionButtonColor forState:UIControlStateNormal];
    [self.actionButton setTitle:item.actionTitle?:@"刷新重试" forState:UIControlStateNormal];
    
    [self setupCustomViewWithItem:item];
}

- (void)setupCustomViewWithItem:(WFDataSourceEmpty *)empty
{
    self.customView = empty.customView;
    empty.customView.frame = self.contentView.bounds;
    [empty.customView removeFromSuperview];
    empty.customView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:empty.customView];
}

- (void)onTapAction:(UIButton *)sender
{
    if (self.item.action) {
        self.item.action();
    }
}
@end
