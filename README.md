# WFDataSource
A block based UITableView/UICollectionView data source

# Features
- Clean Table View & Collection View Code
- Move tableView data source & delegate method into viewDidLoad with blocks
- Mutiple cells with different class to a single array
- Both xib cell and none-xib cell are supported

# Usage

    //cells for cell models
    NSDictionary *modelCellMap = @{ @"DemoCellModel":@"DemoCell", @"DemoCellModel_XIB":@"DemoCell_XIB" };
                                       
    //create a data source
    WFDataSource *dataSource = [[WFDataSource alloc] initWithModelCellMap:modelCellMap cellConfigBlock:^(id cell, id item, NSIndexPath *indexPath) {
        [cell configCellWithItem:item];
    }];
    
    //on select cell
    dataSource.didSelectCellBlock = ^(id item, NSIndexPath *indexPath) {
        NSLog(@"%@ - section %@, row %@",item, @(indexPath.section), @(indexPath.row));
    };
    
    //cell height
    dataSource.heightForRow = ^CGFloat (id item, NSIndexPath *indexPath) {
        return 44;
    };
    
    //section header view
    dataSource.headerViewForSection = ^ UIView *(id sectionItem, NSInteger section){
        WFDataSourceSection *sectionData = (WFDataSourceSection *)sectionItem;
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
        
    //reload cell with model array
    [self.dataSource reloadWithSectionItems:[self sectionModels]];
    
    //or
    [self.dataSource reloadWithItems:[self models]];


