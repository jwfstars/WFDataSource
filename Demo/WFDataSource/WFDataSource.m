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

@property (nonatomic, copy) wf_CellConfigureBlock configureCellBlock;
@property (nonatomic, strong) NSMutableDictionary *modelCellMap;

@property (nonatomic,   copy) NSDictionary *(^customSectionProperties)();
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
        [self.sectionItems addObjectsFromArray:sectionItems];
        [self.modelCellMap addEntriesFromDictionary:map];
        self.configureCellBlock = [block copy];
    }
    return self;
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
        NSLog(@"count = %@",@(secion.sectionItems.count));
        [self insertNewItems:newItems atIndexPath:[NSIndexPath indexPathForItem:secion.sectionItems.count inSection:0]];
    }
}

- (void)insertNewItems:(NSArray *)newItems atIndexPath:(NSIndexPath *)indexPath
{
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
    /*处理重复情况*/
    id lastSectionItem = [self.sectionItems objectAtIndex:indexPath.section - 1];
    id newFirstSectionItem = sectionItems.firstObject;
    NSString *title = [self sectionPropertiesMap][SECTION_TITLE_NAME];
    if ([[lastSectionItem valueForKey:title] isEqual:[newFirstSectionItem valueForKey:title]]) {
        [self insertNewItems:[newFirstSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] atIndexPath:[NSIndexPath indexPathForItem:[[lastSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] count] inSection:indexPath.section-1]];
        [sectionDatasM removeObject:newFirstSectionItem];
    }
    /***********/
    
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
    NSString *cellIdentifier;
    id item = [self itemAtIndexPath:indexPath];
    
    if (self.modelCellMap.count) {
        NSString *classString = NSStringFromClass([item class]);
        cellIdentifier = [self.modelCellMap objectForKey:classString];
        if (!cellIdentifier) {
            @throw [NSException exceptionWithName:@"cellIdentifier 异常" reason:classString userInfo:self.modelCellMap];
        }
    }else {
        cellIdentifier = @"UITableViewCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        Class cellClass = NSClassFromString(cellIdentifier);
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        if (!cell) {
            @throw [NSException exceptionWithName:@"cellIdentifier 异常" reason:cellIdentifier userInfo:self.modelCellMap];
        }
    }
    self.configureCellBlock(cell, item, indexPath);
    return cell;
}

#pragma mark  UITableView Height

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    if (self.heightForRow) {
        return self.heightForRow(item, indexPath);
    }
    return self.tableView.rowHeight;
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
        return self.headerViewForSection(self.sectionItems[section], section);
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
    if (self.didSelectCellBlock) {
        self.didSelectCellBlock(item, indexPath);
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
    NSString *cellIdentifier;
    id item = [self itemAtIndexPath:indexPath];
    
    if (self.modelCellMap.count) {
        NSString *classString = NSStringFromClass([item class]);
        cellIdentifier = [self.modelCellMap objectForKey:classString];
        if (!cellIdentifier) {
            @throw [NSException exceptionWithName:@"cellIdentifier 异常" reason:classString userInfo:self.modelCellMap];
        }
    }else {
        cellIdentifier = @"UICollectionViewCell";
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    self.configureCellBlock(cell, item, indexPath);
    return cell;
}


#pragma mark - UICollection Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    if (self.didSelectCellBlock) {
        self.didSelectCellBlock(item, indexPath);
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionViewLayoutSize) {
        id item = [self itemAtIndexPath:indexPath];
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
        self.didEndDisplayCellBlock(cell, item, indexPath);
    }
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
        return sectionSubArray[indexPath.row];
    }else {
        return nil;
    }
}

- (NSArray *)itemsArray
{
    return [[_sectionItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] copy];
}




#pragma mark -  lazy

- (NSMutableDictionary *)modelCellMap
{
    if (_modelCellMap == nil) {
        _modelCellMap = [[NSMutableDictionary alloc]init];
    }
    return _modelCellMap;
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
    if (self.modelCellMap.count) {
        [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
            NSString *nibPath = [[NSBundle mainBundle] pathForResource:cellClassString ofType:@"nib"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:nibPath]) {
                [tableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
            }else {
                Class cellClass = NSClassFromString(cellClassString);
                [tableView registerClass:cellClass forCellReuseIdentifier:cellClassString];
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
    if (self.modelCellMap.count) {
        [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
            NSString *nibPath = [[NSBundle mainBundle] pathForResource:cellClassString ofType:@"nib"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:nibPath]) {
                [collectionView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellWithReuseIdentifier:cellClassString];
            }else {
                Class cellClass = NSClassFromString(cellClassString);
                [collectionView registerClass:cellClass forCellWithReuseIdentifier:cellClassString];
            }
        }];
    }
    [collectionView reloadData];
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
