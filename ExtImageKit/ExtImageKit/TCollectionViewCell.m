//
//  TCollectionViewCell.m
//  ExtImageKit
//
//  Created by YDJ on 14/12/23.
//  Copyright (c) 2014年 ydj. All rights reserved.
//

#import "TCollectionViewCell.h"

@implementation TCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        
        _imageView= [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_imageView];
        
        _titleLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 20)];
        _titleLabel.backgroundColor=[UIColor clearColor];
        _titleLabel.font=[UIFont systemFontOfSize:13];
        _titleLabel.textColor=[UIColor redColor];
        [self addSubview:_titleLabel];
        
        
    }
    return self;
}

@end
