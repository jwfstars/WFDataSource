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
        
    self.dataSource.tableView = self.tableView;
    
    //reload cell with model array
    [self.dataSource reloadWithSectionItems:[self sectionModels]];
    
    //or
    [self.dataSource reloadWithItems:[self models]];

# 中文文档
基于block的TableView/CollectionView数据源和代理方法的封装

# 特性
- 让 Table View & Collection 代码更加整洁
- 使用 block 将 tableView 的数据源和代理方法扁平化到 viewDidLoad: 中
- 可包含多个不同类的 cell
- 同时支持 XIB 和纯代码创建的 cell

# 简介
iOS界面开发中，每个控制器中重复度最高的代码，可能就是 TableView 的相关方法了。
    
    - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;  
    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;  
    - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;  

上面的代码在项目中大量出现，Table View 通过这些数据源方法和代理方法与 view controllers 之间传递信息，而几乎所有的任务都在 view controller 中进行。为了避免让 view controllers 做所有的事，我们可以将所有的这些繁琐的任务，交给一个专门的类来处理，view controllers 只需在 viewDidLoad: 中告诉这个类要做什么。基于这个思路，我对 Table View / Collection View 的数据源和代理方法进行了封装。

在MVC模式下，每个 Cell 应该有一个对应的 Model 来处理数据业务，在初始化 WFDataSource 时，需要传入Model与Cell的对应关系。通过block回调，将 cell 与 model 对应起来。
    
    //cells for cell models
    NSDictionary *modelCellMap = @{ @"DemoCellModel":@"DemoCell", @"DemoCellModel_XIB":@"DemoCell_XIB" };
                                       
    //create a data source
    WFDataSource *dataSource = [[WFDataSource alloc] initWithModelCellMap:modelCellMap cellConfigBlock:^(id cell, id item, NSIndexPath *indexPath) {
        [cell configCellWithItem:item];
    }];
 
在项目中往往会出现使用XIB创建的Cell和纯代码Cell混用的情形，而两者在通过 table view 的缓存池机制创建 cell 时的差异，可以通过下面两个方法进行统一。
    
    - (void)registerNib:(nullable UINib *)nib forCellReuseIdentifier:(NSString *)identifier;  
    - (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier;  
    
WFDataSource 对此进行了处理, 传入的cell 支持任意方式创建，并可以混用。Table View 的其他数据源方法和代理方法，通过 block 的方式扁平化处理。

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

dataSource 创建后，需要将绑定的table view 赋给它。并刷新cell

self.dataSource.tableView = self.tableView;
    
    //reload cell with model array
    [self.dataSource reloadWithSectionItems:[self sectionModels]];
    
    //or
    [self.dataSource reloadWithItems:[self models]];
