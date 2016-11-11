//
//  CollectionDataSources.m
//  Magazine
//
//  Created by 江文帆 on 15/9/14.
//  Copyright (c) 2015年 江文帆. All rights reserved.
//

#import "WFDataSource.h"

@interface WFDataSource() <UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy) CellConfigureBlock configureCellBlock;
@property (nonatomic, copy) NSString *cellClassString;
@property (nonatomic, strong) NSMutableDictionary *modelCellMap;
@property (nonatomic,   weak) UIView *collectionHeaderView;
@end

@implementation WFDataSource

@synthesize sectionItems = _sectionItems;

- (id)init
{
    return nil;
}

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

- (NSArray *)itemsArray
{
    return [[_sectionItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] copy];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    tableView.dataSource = self;
    tableView.delegate = self;
    if (!self.doNotUseXib) {
        if (self.cellClassString) {
            [tableView registerNib:[UINib nibWithNibName:self.cellClassString bundle:nil] forCellReuseIdentifier:self.cellClassString];
        }
        if (self.modelCellMap.count) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
                [tableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
            }];
        }
    }
    [tableView reloadData];
}


- (void)setCollectionView:(UICollectionView *)collectionView
{
    [self.modelCellMap removeObjectsForKeys:@[@"VGTEmpty",@"VGTError"]];
    _collectionView = collectionView;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    if (self.doNotUseXib) {
        if (self.cellClassString) {
            [collectionView registerClass:NSClassFromString(self.cellClassString) forCellWithReuseIdentifier:self.cellClassString];
        }
        if (self.modelCellMap.count) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
                [collectionView registerClass:NSClassFromString(cellClassString) forCellWithReuseIdentifier:cellClassString];
            }];
        }
    }else {
        if (self.cellClassString) {
            [collectionView registerNib:[UINib nibWithNibName:self.cellClassString bundle:nil] forCellWithReuseIdentifier:self.cellClassString];
        }
        if (self.modelCellMap.count) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
                [collectionView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellWithReuseIdentifier:cellClassString];
            }];
        }
    }
    
    [collectionView reloadData];
}


//For single section
- (instancetype)initWithItems:(NSArray *)items cellClass:(NSString *)cellClass configureCellBlock:(CellConfigureBlock)configureCellBlock
{
    ArrayDSDefaultSection *section = [ArrayDSDefaultSection new];
    section.sectionTitle = nil;
    section.sectionItems = [items mutableCopy];
    return [self initWithSectionItems:@[section] cellClass:cellClass configureCellBlock:configureCellBlock];
}

//For mutiply sections
- (instancetype)initWithSectionItems:(NSArray *)sectionItems cellClass:(NSString *)cellClass configureCellBlock:(CellConfigureBlock)configureCellBlock
{
    self = [super init];
    if (self) {
        self.cellClassString = cellClass;
        
        [self.sectionItems removeAllObjects];
        [self.sectionItems addObjectsFromArray:sectionItems];
        
        //为sectionItems中的每一个模型的Class关联对应的Cell
        NSMutableArray *subItems = [sectionItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
        NSDictionary *dict = [self classDictOfSectionSubItems:subItems cellClass:self.cellClassString];
        return [self initWithModelCellMap:dict?:@{} sectionItems:sectionItems configureCellBlock:configureCellBlock];
    }
    return self;
}


- (NSDictionary *)classDictOfSectionSubItems:(NSArray *)subItems cellClass:(NSString *)cellClassString
{
    if (!subItems.count) return nil;
    if (subItems.count) {
        NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
        [subItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Class itemClass = [obj class];
            NSString *classString = NSStringFromClass(itemClass);
            if (![classString isEqualToString:@"VGTError"] && ![classString isEqualToString:@"VGTEmpty"]) {
                [dictM setObject:cellClassString forKey:classString];
            }
        }];
        if (dictM.count) {
            return [dictM copy];
        }else {
            return nil;
        }
    }else {
        return nil;
    }
}

- (instancetype)initWithModelCellMap:(NSDictionary *)map items:(NSArray *)items configureCellBlock:(CellConfigureBlock)configureCellBlock
{
    ArrayDSDefaultSection *section = [ArrayDSDefaultSection new];
    section.sectionTitle = nil;
    section.sectionItems = [items mutableCopy];
    return [self initWithModelCellMap:map sectionItems:@[section] configureCellBlock:configureCellBlock];
}

//For Mutyple kinds of Cells - Universal
- (instancetype)initWithModelCellMap:(NSDictionary *)map sectionItems:(NSArray *)sectionItems configureCellBlock:(CellConfigureBlock)configureCellBlock
{
    self = [super init];
    if (self) {
        [self.sectionItems removeAllObjects];
        [self.sectionItems addObjectsFromArray:sectionItems];
        [self.modelCellMap removeAllObjects];
        
        NSDictionary *empty = @{@"VGTEmpty": @"VGTEmptyCell",
                                @"VGTError": @"VGTErrorCell"};
        [self.modelCellMap addEntriesFromDictionary:map];
        [self.modelCellMap addEntriesFromDictionary:empty];
        self.configureCellBlock = [configureCellBlock copy];
    }
    return self;
}

- (instancetype)initWithModelCellMap:(NSDictionary *)map configureCellBlock:(CellConfigureBlock)configureCellBlock
{
    return [self initWithModelCellMap:map items:nil configureCellBlock:configureCellBlock];
}

- (void)reloadWithItems:(NSArray *)items
{
    [self reloadWithItems:items animated:NO];
}

- (void)reloadWithItems:(NSArray *)items animated:(BOOL)animated
{
    ArrayDSDefaultSection *section = [ArrayDSDefaultSection new];
    section.sectionTitle = nil;
    section.sectionItems = [NSMutableArray arrayWithArray:items];
    [self reloadWithSectionItems:@[section] animated:animated];
}

- (void)reloadWithSectionItems:(NSArray *)sectionItems animated:(BOOL)animated
{
    [self.sectionItems removeAllObjects];
    [self.sectionItems addObjectsFromArray:sectionItems];
    
    if (self.cellClassString) {
        NSMutableArray *subItems = [sectionItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
        NSDictionary *dict = [self classDictOfSectionSubItems:subItems cellClass:self.cellClassString];
        if (dict) {
            [self.modelCellMap addEntriesFromDictionary:dict];
            if (!self.doNotUseXib) {
                [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
                    [_tableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
                }];
            }
        }
    }
    
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

- (void)reloadWithSectionItems:(NSArray *)sectionItems
{
    [self reloadWithSectionItems:sectionItems animated:NO];
}


- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (void)addNewItems:(NSArray *)newItems
{
    if (!self.sectionItems.count) {
        [self reloadWithItems:newItems];
    }else {
        ArrayDSDefaultSection *secion = self.sectionItems.firstObject;
        NSLog(@"count = %@",@(secion.sectionItems.count));
        [self insertNewItems:newItems atIndexPath:[NSIndexPath indexPathForItem:secion.sectionItems.count inSection:0]];
    }
}
- (void)insertNewItems:(NSArray *)newItems atIndex:(NSInteger)index
{
    [self insertNewItems:newItems atIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}
- (void)insertNewItems:(NSArray *)newItems atIndexPath:(NSIndexPath *)indexPath
{
    [self insertNewSectionItemsOrItems:newItems atIndexPath:indexPath type:0];
}

- (void)addNewSectionItems:(NSArray *)newSectionItems
{
    [self insertNewSectionItems:newSectionItems atSectionIndex:self.sectionItems.count];
}

- (void)insertNewSectionItems:(NSArray *)sectionItems atSectionIndex:(NSInteger)sectionIndex
{
    [self insertNewSectionItemsOrItems:sectionItems atIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex] type:1];
}


- (void)insertNewSectionItemsOrItems:(NSArray *)sectionItemsOrItems atIndexPath:(NSIndexPath *)indexPath type:(NSInteger)type
{
    if (self.cellClassString) {
        if (type == 0) {
            if (sectionItemsOrItems.count) {
                NSDictionary *dict = [self classDictOfSectionSubItems:sectionItemsOrItems cellClass:self.cellClassString];
                [self.modelCellMap addEntriesFromDictionary:dict];
            }
        }else {
            //type == 1
            NSMutableArray *subItems = [sectionItemsOrItems.firstObject valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
            NSDictionary *dict = [self classDictOfSectionSubItems:subItems cellClass:self.cellClassString];
            if (dict) {
                [self.modelCellMap addEntriesFromDictionary:dict];
            }
        }
        if (!self.doNotUseXib) {
            [self.modelCellMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *cellClassString, BOOL * _Nonnull stop) {
                [_tableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
            }];
        }
    }

    NSMutableArray *sectionDatasM = [NSMutableArray arrayWithArray:sectionItemsOrItems];
    if (type == 0) {
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (NSInteger startIndex = indexPath.item; startIndex < indexPath.item + sectionItemsOrItems.count; startIndex ++) {
            [indexSet addIndex:startIndex];
        }
        NSMutableArray *sectionitem = [self.sectionItems objectAtIndex:indexPath.section];
        [((NSMutableArray *)[sectionitem mutableArrayValueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]] ) insertObjects:sectionItemsOrItems atIndexes:indexSet];
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:sectionItemsOrItems.count];
        [sectionItemsOrItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath *indexPathToAdd = [NSIndexPath indexPathForItem:indexPath.item + idx inSection:indexPath.section];
            [indexPaths addObject:indexPathToAdd];
        }];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.collectionView performBatchUpdates:^{
            [self.collectionView insertItemsAtIndexPaths:indexPaths];
        } completion:nil];
    }else {
        /*处理重复情况*/
        id lastSectionItem = [self.sectionItems objectAtIndex:indexPath.section - 1];
        id newFirstSectionItem = sectionItemsOrItems.firstObject;
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
}



- (NSDictionary *)sectionPropertiesMap
{
    if (self.customSectionProperties) {
        return self.customSectionProperties();
    }else {
        return @{SECTION_CLASS_NAME:@"ArrayDSDefaultSection", SECTION_TITLE_NAME:@"sectionTitle",SECTION_SUBARRAY_NAME:@"sectionItems"};
    }
}









#pragma mark - UITableViewDataSource
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
    Class cellClass = NSClassFromString(cellIdentifier);
    
    UITableViewCell *cell;
    if (self.doNotUseXib) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            if (cellClass) {
                cell = [[cellClass alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }else {
                cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            }
        }
    }else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    
    self.configureCellBlock(cell, item, indexPath);
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemAtIndexPath:indexPath];
    if (self.heightForRow) {
        return self.heightForRow(item, indexPath);
    }
    return self.tableView.rowHeight;
}

- (CGFloat)tableViewRealHeight {
    return _tableView.frame.size.height - self.tableView.contentInset.top;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.headerViewForSection) {
        return self.headerViewForSection(self.sectionItems[section], section);
    }
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.footerViewForSection) {
        if (self.heightForFooterInSection) {
            return self.heightForFooterInSection(self.sectionItems[section], section);
        }
        UIView *headerView = self.footerViewForSection(self.sectionItems[section], section);
        CGFloat height = CGRectGetHeight(headerView.frame);
        return height;
    }else {
        return 0;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.footerViewForSection) {
        return self.headerViewForSection(self.sectionItems[section], section);
    }
    return nil;
}


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

- (void)reloadSectionAtIndex:(NSInteger)index
{
    NSRange range = NSMakeRange(index, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:sectionToReload];
    } completion:nil];
    [self.tableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.canEditForRow) {
        id item = [self itemAtIndexPath:indexPath];
        return self.canEditForRow(item, indexPath);
    }
    return self.tableView.editing;
}

/** 删除一个单元格  ui和 数据上 */
- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath {
    [self removeCellAtIndexPath:indexPath animation:UITableViewRowAnimationFade];
}

/** 删除一个单元格  ui和 数据上 自定义动画 */
- (void)removeCellAtIndexPath:(NSIndexPath *)indexPath animation:(UITableViewRowAnimation)animation {
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










#pragma mark - UICollectionDataSource
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
    
    if (!cellIdentifier) {
        return nil;
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    self.configureCellBlock(cell, item, indexPath);
    return cell;
}


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


#pragma mark - UICollectionViewDelegate
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

#pragma mark - ScrollView
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
            currentIndexPath = [[self.collectionView indexPathsForVisibleItems]firstObject];
        }else {
            currentIndexPath = [[self.tableView indexPathsForVisibleRows]firstObject];
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


- (void)scrollToEndWithDelay:(NSTimeInterval)delay animated:(BOOL)animated
{
    if (self.itemsArray.count||self.sectionItems.count) {
        NSIndexPath *indexPath;
        if (self.sectionItems.count) {
            id lastSectionItem = [self.sectionItems objectAtIndex:self.sectionItems.count-1];
            NSMutableArray *sectionSubArray = [lastSectionItem valueForKey:[self sectionPropertiesMap][SECTION_SUBARRAY_NAME]];
            indexPath = [NSIndexPath indexPathForItem:sectionSubArray.count-1 inSection:self.sectionItems.count-1];
        }else {
            indexPath = [NSIndexPath indexPathForItem:self.itemsArray.count-1 inSection:0];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
        });
    }
}
@end


@implementation ArrayDSDefaultSection
- (NSMutableArray *)sectionItems
{
    if (_sectionItems == nil) {
        _sectionItems = [NSMutableArray array];
    }
    return _sectionItems;
}
@end
