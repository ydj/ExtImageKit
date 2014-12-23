//
//  UIImage+IncreaseExt.h
//  ExtImageKit
//
//  Created by YDJ on 14/11/26.
//  Copyright (c) 2014年 ydj. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kUIImageIncreaseKit_Ext 1


///图片的修剪类型
typedef enum
{
    ExtCropModeTopLeft,
    ExtCropModeTopCenter,
    ExtCropModeTopRight,
    ExtCropModeBottomLeft,
    ExtCropModeBottomCenter,
    ExtCropModeBottomRight,
    ExtCropModeLeftCenter,
    ExtCropModeRightCenter,
    ExtCropModeCenter
} ExtCropMode;


///修改图片的填充方式
typedef enum
{
    ExtResizeModeScaleToFill,
    ExtResizeModeAspectFit,
    ExtResizeModeAspectFill
} ExtResizeMode;

///保存图片类型
typedef enum
{
    ExtImageTypePNG,
    ExtImageTypeJPEG,
    ExtImageTypeGIF,
    ExtImageTypeBMP,
    ExtImageTypeTIFF
} ExtImageType;


/* Number of components for an opaque grey colorSpace = 3 */
#define kNumberOfComponentsPerGreyPixel_Ext 3
/* Number of components for an ARGB pixel (Alpha / Red / Green / Blue) = 4 */
#define kNumberOfComponentsPerARBGPixel_Ext 4
/* Minimun value for a pixel component */
#define kMinPixelComponentValue_Ext (UInt8)0
/* Maximum value for a pixel component */
#define kMaxPixelComponentValue_Ext (UInt8)255

/* Convert degrees value to radians */
#define DEGREES_TO_RADIANS_EXT(__DEGREES) (__DEGREES * 0.017453293) // (M_PI / 180.0f)
/* Convert radians value to degrees */
#define RADIANS_TO_DEGREES_EXT(__RADIANS) (__RADIANS * 57.295779513) // (180.0f / M_PI)




/**
 *	图片得增强处理
 */
@interface UIImage (ExtImageKit)

///////Refkection

/**
*	图像反射,类似垂直翻转
*	@param height    高度
*	@param fromAlpha 当前alpha
*	@param toAlpha   目标alpha
*	@return 修改后得图片
*/
-(UIImage*)reflectedImageWithHeight_Ext:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha;


///Resizing


/**
 *	修剪图片
 *	@param newSize  范围大小
 *	@param cropMode 修剪后显示的类型
 *	@return 新图片
 */
-(UIImage*)cropToSize_Ext:(CGSize)newSize usingMode:(ExtCropMode)cropMode;

/**
 *	修剪图片，默认类型为ExtCropModeTopLeft
 *	@param newSize 范围大小
 *	@return 新图片
 */
-(UIImage*)cropToSize_Ext:(CGSize)newSize;

/**
 *	图片缩放
 *	@param scaleFactor 比例
 *	@return 新图片
 */
-(UIImage*)scaleByFactor_Ext:(float)scaleFactor;

/**
 *	缩放图片到指定尺寸
 *	@param newSize    新尺寸
 *	@param resizeMode 图片显示的类型
 *	@return 新图片
 */
-(UIImage*)scaleToSize_Ext:(CGSize)newSize usingMode:(ExtResizeMode)resizeMode;

/**
 *	缩放图片到指定尺寸，默认显示类型为ExtResizeModeScaleToFill
 *	@param newSize 新尺寸
 *	@return 新图片
 */
-(UIImage*)scaleToSize_Ext:(CGSize)newSize;


/**
 *	缩放图片到指定尺寸，默认显示类型为ExtResizeModeScaleToFill(Same as 'scale to fill' in IB.)
 *	@param newSize 新尺寸
 *	@return 新图片
 */
-(UIImage*)scaleToFillSize_Ext:(CGSize)newSize;

//

/**
 *	缩放图片到指定的尺寸，默认显示的类型为ExtResizeModeAspectFit(Preserves aspect ratio. Same as 'aspect fit' in IB.)
 *	@param newSize 新尺寸
 *	@return 新图片
 */
-(UIImage*)scaleToFitSize_Ext:(CGSize)newSize;

//
/**
 *	缩放图片到指定的尺寸，默认显示的类型为ExtResizeModeAspectFill( Preserves aspect ratio. Same as 'aspect fill' in IB.)
 *	@param newSize 新尺寸
 *	@return 新图片
 */
-(UIImage*)scaleToCoverSize_Ext:(CGSize)newSize;


/////Rotating

/**
 *	图片旋转
 *	@param radians 旋转的弧度
 *	@return 新图片
 */
-(UIImage*)rotateInRadians_Ext:(float)radians;

/**
 *	图片旋转的角度
 *	@param degrees 角度
 *	@return 新图片
 */
-(UIImage*)rotateInDegrees_Ext:(float)degrees;

/**
 *	图片的像素旋转弧度
 *	@param radians 选择的弧度
 *	@return 新图片
 */
-(UIImage*)rotateImagePixelsInRadians_Ext:(float)radians;

/**
 *	图片的像素旋转
 *	@param degrees 角度
 *	@return 新图片
 */
-(UIImage*)rotateImagePixelsInDegrees_Ext:(float)degrees;

/**
 *	图片垂直切换
 *	@return 新图片
 */
-(UIImage*)verticalFlip_Ext;

/**
 *	图片水平却换
 *	@return 新图片
 */
-(UIImage*)horizontalFlip_Ext;



////Save

/**
 *	保存图片到指定的url
 *	@param url       路径
 *	@param uti       图片得类型 kUTTypePNG ...
 *	@param fillColor 背景图的颜色
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToURL_Ext:(NSURL*)url uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor;

/**
 *	保存图片
 *	@param url       路径
 *	@param type      图片类型
 *	@param fillColor 背景颜色
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToURL_Ext:(NSURL*)url type:(ExtImageType)type backgroundFillColor:(UIColor*)fillColor;

/**
 *	保存图片，默认png格式
 *	@param url 保存的路径
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToURL_Ext:(NSURL*)url;

/**
 *	保存图片
 *	@param path      路径
 *	@param uti       图片得类型 kUTTypePNG ...
 *	@param fillColor 背景的颜色
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToPath_Ext:(NSString*)path uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor;

/**
 *	保存图片
 *	@param path      路径
 *	@param type      图片类型
 *	@param fillColor 背景颜色
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToPath_Ext:(NSString*)path type:(ExtImageType)type backgroundFillColor:(UIColor*)fillColor;

/**
 *	保存图片 默认png格式
 *	@param path 路径
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToPath_Ext:(NSString*)path;

/**
 *	保存图片到相册
 *	@return YES-成功 NO-不成功
 */
-(BOOL)saveToPhotosAlbum_Ext;


+(NSString*)extensionForUTI_Ext:(CFStringRef)uti;


///Masking

/**
 *  两个图片合成一个
 *	@param mask 图片
 *	@return 新图片
 */
-(UIImage*)maskWithImage_Ext:(UIImage*)mask;

/**
 *	自动增强
 *	@return 新图片
 */
-(UIImage*)autoEnhance_Ext;

/**
 *	红眼校正
 *	@return 新图片
 */
-(UIImage*)redEyeCorrection_Ext;


/**
 *  高斯模糊效果
 *	@param bias 偏差值
 *	@return 新图片
 */
-(UIImage*)gaussianBlurWithBias_Ext:(NSInteger)bias;



///Filtering


/**
 *	图片变亮
 *	@param factor 值的范围在(-255, 255)之间
 *	@return 新图片
 */
-(UIImage*)brightenWithValue_Ext:(float)factor;

/**
 *	对比度调整
 *	@param value 值的范围在(-255, 255)之间
 *	@return 新图片
 */
-(UIImage*)contrastAdjustmentWithValue_Ext:(float)value;

/**
 *	边缘检测
 *	@param bias 偏差值
 *	@return 新图片
 */
-(UIImage*)edgeDetectionWithBias_Ext:(NSInteger)bias;


/**
 *	浮雕配置
 *	@param bias 偏差值
 *	@return 新图片
 */
-(UIImage*)embossWithBias_Ext:(NSInteger)bias;


/**
 *	gamma(亮度线性)校正
 *	@param value  值的范围(0.01, 8)
 *	@return 新图片
 */
-(UIImage*)gammaCorrectionWithValue_Ext:(float)value;

/**
 *  灰阶
 *	@return 新图片
 */
-(UIImage*)grayscale_Ext;

/**
 *  颠倒，倒置
 *	@return 新图片
 */
-(UIImage*)invert_Ext;


/**
 *	不透明度
 *	@param value 值的范围0-1
 *	@return 新图片
 */
-(UIImage*)opacity_Ext:(float)value;


/**
 *	图片墨色处理
 *	@return 新图片
 */
-(UIImage*)sepia_Ext;


/**
 *	锐化处理 削尖,磨
 *	@param bias 偏差值
 *	@return 新图片
 */
-(UIImage*)sharpenWithBias_Ext:(NSInteger)bias;

/**
 *	非锐化处理
 *	@param bias 偏差值
 *	@return 新图片
 */
-(UIImage*)unsharpenWithBias_Ext:(NSInteger)bias;


/**
 *	膨胀处理
 *	@return 新图片
 */
- (UIImage *)dilate_Ext;

/**
 *	加倍膨胀处理
 *	@param iterations 倍数
 *	@return 新图片
 */
- (UIImage *)dilateWithIterations_Ext:(int)iterations;

/**
 *	侵蚀处理
 *	@return 新图片
 */
- (UIImage *)erode_Ext;

/**
 *	加倍侵蚀处理
 *	@param iterations 倍数
 *	@return 新图片
 */
- (UIImage *)erodeWithIterations_Ext:(int)iterations;

/**
 *	膨胀后和原图融合处理
 *	@param iterations 膨胀倍数 最小是1
 *	@return 新图片
 */
- (UIImage *)tophatWithIterations_Ext:(int)iterations;

/**
 *	侵蚀后和原图融合处理
 *	@param iterations  侵蚀倍数
 *	@return 新图片
 */
- (UIImage *)blackhatWithIterations_Ext:(int)iterations;


/**
 *	图片融合
 *	@param overlayImage 其他图片
 *	@param blendMode    融合的模式
 *	@param alpha        alpha
 *	@return 新图片
 */
- (UIImage *)imageBlendedWithImage_Ext:(UIImage *)overlayImage blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha;


/**
 *	图片均衡处理
 *	@return 新图片
 */
- (UIImage *)equalization_Ext;




@end
