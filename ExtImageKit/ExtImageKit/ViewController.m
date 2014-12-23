//
//  ViewController.m
//  ExtImageKit
//
//  Created by YDJ on 14/12/23.
//  Copyright (c) 2014年 ydj. All rights reserved.
//

#import "ViewController.h"
#import "TCollectionViewCell.h"
#import "UIImage+ExtImageKit.h"


@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic,strong)UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize=CGSizeMake(100, 90);
    flowLayout.sectionInset=UIEdgeInsetsMake(0, 5, 0, 5);
    
    _collectionView=[[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.delegate=self;
    _collectionView.dataSource=self;
    _collectionView.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:_collectionView];
    

    [_collectionView registerClass:[TCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 33;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    TCollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    

    UIImage * image=[UIImage imageNamed:@"sa1.png"];
    NSString * string=nil;
    switch (indexPath.item) {
        case 0:
        {
            string=@"原图";
            break;
        }
        case 1:
        {
            image=[image gaussianBlurWithBias_Ext:5];
            string=@"gaussianBlur";
            break;
        }
        case 2:
        {
            image=[image autoEnhance_Ext];
            string=@"auto Enhance";
            break;
        }
        case 3:
        {
            image=[image redEyeCorrection_Ext];
            string=@"redEye";
            break;
        }
        case 4:
        {
            image=[image brightenWithValue_Ext:-100];
            string=@"brighten";
            break;
        }
        case 5:
        {
            image=[image contrastAdjustmentWithValue_Ext:-100];
            string=@"contrastAdjustment";
            break;
        }
        case 6:
        {
            image=[image edgeDetectionWithBias_Ext:0];
            string=@"edgeDetection";
            break;
        }
        case 7:
        {
            image=[image embossWithBias_Ext:0];
            string=@"emboss";
            break;
        }
        case 8:
        {
            image=[image gammaCorrectionWithValue_Ext:5];
            string=@"gammaCorrection";
            break;
        }
        case 9:
        {
            image=[image grayscale_Ext];
            string=@"grayScale";
            break;
        }
        case 10:
        {
            image=[image invert_Ext];
            string=@"invert";
            break;
        }
        case 11:
        {
            image=[image opacity_Ext:0.5];
            string=@"opacity";
            break;
        }
        case 12:
        {
            image=[image sepia_Ext];
            string=@"sepia";
            break;
        }
        case 13:
        {
            image=[image sharpenWithBias_Ext:200];
            string=@"sharpen";
            break;
        }
        case 14:
        {
            image=[image unsharpenWithBias_Ext:200];
            string=@"unsharpen";
            break;
        }
        case 15:
        {
            image=[image maskWithImage_Ext:[UIImage imageNamed:@"a.png"]];
            string=@"mask";
            break;
        }
        case 16:
        {
            image=[image reflectedImageWithHeight_Ext:260 fromAlpha:1 toAlpha:0.5];
            string=@"reflected";
            break;
        }
        case 17:
        {
            image=[image cropToSize_Ext:CGSizeMake(50, 50) usingMode:ExtCropModeLeftCenter];
            string=@"cropToSize";
            break;
        }
        case 18:
        {
            image=[image scaleByFactor_Ext:0.5];
            string=@"scaleByFactor";
            break;
        }
        case 19:
        {
            image=[image scaleToSize_Ext:CGSizeMake(20, 20)];
            string=@"scaleToSize";
            break;
        }
        case 20:
        {
            image=[image scaleToFitSize_Ext:CGSizeMake(20, 20)];
            string=@"scaleToFit";
            break;
        }
        case 21:
        {
            image=[image scaleToCoverSize_Ext:CGSizeMake(20, 20)];
            string=@"scaletoCoverSize";
            break;
        }
        case 22:
        {
            image=[image rotateInRadians_Ext:100];
            string=@"rotateInRadians";
            break;
        }
        case 23:
        {
            image=[image rotateInDegrees_Ext:90];
            string=@"rotateInDegrees_Ext";
            break;
        }
        case 24:
        {
            image=[image rotateImagePixelsInRadians_Ext:40];
            string=@"rotatePixelsInRadians";
            break;
        }
        case 25:
        {
            image=[image rotateImagePixelsInDegrees_Ext:100];
            string=@"rotatePixelsInDegrees";
            break;
        }
        case 26:
        {
            image=[image verticalFlip_Ext];
            string=@"verticalFlip_Ext";
            break;
        }
        case 27:
        {
            image=[image horizontalFlip_Ext];
            string=@"horizontalFlip_Ext";
            break;
        }
        case 28:
        {
            image=[image equalization_Ext];
            string=@"quealization";
            break;
        }
        case 29:
        {
            image=[image tophatWithIterations_Ext:5];
            string=@"tophat";
            break;
        }
        case 30:
        {
            image=[image blackhatWithIterations_Ext:0];
            string=@"blackhat";
            break;
        }
        case 31:
        {
            image=[image sharpenWithBias_Ext:5];
            string=@"sharpen";
            break;
        }
        case 32:
        {
            image=[image unsharpenWithBias_Ext:5];
            string=@"unsharpen";
            break;
        }
        default:
            break;
    }
    
    cell.imageView.image=image;
    cell.titleLabel.text=string;
    
    
    
    
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
