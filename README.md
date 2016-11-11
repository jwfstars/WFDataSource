# WFDataSource
A block based UITableView/UICollectionView data source

# Features
- Clean Table View & Collection View Code
- Move tableView data source & delegate method into viewDidLoad with blocks
- Mutiple cells with different class to a single array
- Both xib cell and none-xib cell are supported

# Useage

    //create a data source
    WFDataSource *dataSource = [[WFDataSource alloc] initWithModelCellMap:modelCellMap cellConfigBlock:^(id cell, id item, NSIndexPath *indexPath) {
        [cell configCellWithItem:item];
    }];



