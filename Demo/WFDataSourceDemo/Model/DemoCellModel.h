//
//  DemoCellModel.h
//  WFDataSourceDemo
//
//  Created by 江文帆 on 16/11/11.
//  Copyright © 2016年 江文帆. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DemoCellModel : NSObject
@property (nonatomic,   copy) NSString *name;
@property (nonatomic,   copy) NSString *imageName;

@property (nonatomic, assign) CGFloat cellHeight;
@end
