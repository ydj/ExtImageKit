//
//  UIImage+IncreaseExt.m
//  ExtImageKit
//
//  Created by YDJ on 14/11/26.
//  Copyright (c) 2014年 ydj. All rights reserved.
//

#import "UIImage+ExtImageKit.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import <ImageIO/ImageIO.h> // For CGImageDestination
#import <MobileCoreServices/MobileCoreServices.h> // For the UTI types constants
#import <AssetsLibrary/AssetsLibrary.h> // For photos album saving


////处理图片底层方法

static CIContext* __ciContext_Ext = nil;
static CGColorSpaceRef __rgbColorSpace_Ext = NULL;

///方法声明
CGColorSpaceRef GetRGBColorSpace_Ext(void);


CGContextRef CreateARGBBitmapContext_Ext(const size_t width, const size_t height, const size_t bytesPerRow, BOOL withAlpha)
{
    /// Use the generic RGB color space
    /// We avoid the NULL check because CGColorSpaceRelease() NULL check the value anyway, and worst case scenario = fail to create context
    /// Create the bitmap context, we want pre-multiplied ARGB, 8-bits per component
    CGImageAlphaInfo alphaInfo = (withAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, bytesPerRow, GetRGBColorSpace_Ext(), kCGBitmapByteOrderDefault | alphaInfo);
    
    return bmContext;
}

// The following function was taken from the increadibly awesome HockeyKit
// Created by Peter Steinberger on 10.01.11.
// Copyright 2012 Peter Steinberger. All rights reserved.
CGImageRef CreateGradientImage_Ext(const size_t pixelsWide, const size_t pixelsHigh, const CGFloat fromAlpha, const CGFloat toAlpha)
{
    // gradient is always black-white and the mask must be in the gray colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // create the bitmap context
    CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
    
    // define the start and end grayscale values (with the alpha, even though
    // our bitmap context doesn't support alpha the gradient requires it)
    CGFloat colors[] = {toAlpha, 1.0f, fromAlpha, 1.0f};
    
    // create the CGGradient and then release the gray color space
    CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGColorSpaceRelease(colorSpace);
    
    // create the start and end points for the gradient vector (straight down)
    CGPoint gradientEndPoint = CGPointZero;
    CGPoint gradientStartPoint = (CGPoint){.x = 0.0f, .y = pixelsHigh};
    
    // draw the gradient into the gray bitmap context
    CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint, gradientEndPoint, kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(grayScaleGradient);
    
    // convert the context into a CGImageRef and release the context
    CGImageRef theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
    CGContextRelease(gradientBitmapContext);
    
    // return the imageref containing the gradient
    return theCGImage;
}

CIContext* GetCIContext_Ext(void)
{
    if (!__ciContext_Ext)
    {
        NSNumber* num = [[NSNumber alloc] initWithBool:NO];
        NSDictionary* opts = [[NSDictionary alloc] initWithObjectsAndKeys:num, kCIContextUseSoftwareRenderer, nil];
        __ciContext_Ext = [CIContext contextWithOptions:opts];
    }
    return __ciContext_Ext;
}

CGColorSpaceRef GetRGBColorSpace_Ext(void)
{
    if (!__rgbColorSpace_Ext)
    {
        __rgbColorSpace_Ext = CGColorSpaceCreateDeviceRGB();
    }
    return __rgbColorSpace_Ext;
}

void ImagesKitRelease_Ext(void)
{
    if (__rgbColorSpace_Ext)
        CGColorSpaceRelease(__rgbColorSpace_Ext), __rgbColorSpace_Ext = NULL;
    if (__ciContext_Ext)
        __ciContext_Ext = nil;
}

BOOL ImageHasAlpha_Ext(CGImageRef imageRef)
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
    
    return hasAlpha;
}



///


///Filtering
/* Sepia values for manual filtering (< iOS 5) */
static float const __ExtSepiaFactorRedRed = 0.393f;
static float const __ExtSepiaFactorRedGreen = 0.349f;
static float const __ExtSepiaFactorRedBlue = 0.272f;
static float const __ExtSepiaFactorGreenRed = 0.769f;
static float const __ExtSepiaFactorGreenGreen = 0.686f;
static float const __ExtSepiaFactorGreenBlue = 0.534f;
static float const __ExtSepiaFactorBlueRed = 0.189f;
static float const __ExtSepiaFactorBlueGreen = 0.168f;
static float const __ExtSepiaFactorBlueBlue = 0.131f;

/* Negative multiplier to invert a number */
static float __ExtNegativeMultiplier = -1.0f;

#pragma mark - Edge detection kernels
/* vImage kernel */
/*static int16_t __s_edgedetect_kernel_3x3[9] = {
	-1, -1, -1,
	-1, 8, -1,
	-1, -1, -1
 };*/
/* vDSP kernel */
static float __f_edgedetect_kernel_3x3_Ext[9] = {
    -1.0f, -1.0f, -1.0f,
    -1.0f, 8.0f, -1.0f,
    -1.0f, -1.0f, -1.0f
};

#pragma mark - Emboss kernels
/* vImage kernel */
static int16_t __s_emboss_kernel_3x3_Ext[9] = {
    -2, 0, 0,
    0, 1, 0,
    0, 0, 2
};

#pragma mark - Sharpen kernels
/* vImage kernel */
static int16_t __s_sharpen_kernel_3x3_Ext[9] = {
    -1, -1, -1,
    -1, 9, -1,
    -1, -1, -1
};

#pragma mark - Unsharpen kernels
/* vImage kernel */
static int16_t __s_unsharpen_kernel_3x3_Ext[9] = {
    -1, -1, -1,
    -1, 17, -1, 
    -1, -1, -1
};


////


static int16_t __s_gaussianblur_kernel_5x5_Ext[25] = {
    1, 4, 6, 4, 1,
    4, 16, 24, 16, 4,
    6, 24, 36, 24, 6,
    4, 16, 24, 16, 4,
    1, 4, 6, 4, 1
};



@implementation UIImage (ExtImageKit)

-(UIImage*)reflectedImageWithHeight_Ext:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha
{
    if (!height)
        return nil;
    
    // create a bitmap graphics context the size of the image
    UIGraphicsBeginImageContextWithOptions((CGSize){.width = self.size.width, .height = height}, NO, 0.0f);
    CGContextRef mainViewContentContext = UIGraphicsGetCurrentContext();
    
    // create a 2 bit CGImage containing a gradient that will be used for masking the
    // main view content to create the 'fade' of the reflection. The CGImageCreateWithMask
    // function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
    CGImageRef gradientMaskImage = CreateGradientImage_Ext(1, height, fromAlpha, toAlpha);
    
    // create an image by masking the bitmap of the mainView content with the gradient view
    // then release the  pre-masked content bitmap and the gradient bitmap
    CGContextClipToMask(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = self.size.width, .size.height = height}, gradientMaskImage);
    CGImageRelease(gradientMaskImage);
    
    // draw the image into the bitmap context
    CGContextDrawImage(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size = self.size}, self.CGImage);
    
    // convert the finished reflection image to a UIImage
    UIImage* theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return theImage;
}





-(UIImage*)cropToSize_Ext:(CGSize)newSize usingMode:(ExtCropMode)cropMode
{
    const CGSize size = self.size;
    CGFloat x, y;
    switch (cropMode)
    {
        case ExtCropModeTopLeft:
            x = y = 0.0f;
            break;
        case ExtCropModeTopCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = 0.0f;
            break;
        case ExtCropModeTopRight:
            x = size.width - newSize.width;
            y = 0.0f;
            break;
        case ExtCropModeBottomLeft:
            x = 0.0f;
            y = size.height - newSize.height;
            break;
        case ExtCropModeBottomCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = size.height - newSize.height;
            break;
        case ExtCropModeBottomRight:
            x = size.width - newSize.width;
            y = size.height - newSize.height;
            break;
        case ExtCropModeLeftCenter:
            x = 0.0f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case ExtCropModeRightCenter:
            x = size.width - newSize.width;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case ExtCropModeCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        default: // Default to top left
            x = y = 0.0f;
            break;
    }
    
    if (self.imageOrientation == UIImageOrientationLeft || self.imageOrientation == UIImageOrientationLeftMirrored || self.imageOrientation == UIImageOrientationRight || self.imageOrientation == UIImageOrientationRightMirrored)
    {
        CGFloat temp = x;
        x = y;
        y = temp;
    }
    
    CGRect cropRect = CGRectMake(x * self.scale, y * self.scale, newSize.width * self.scale, newSize.height * self.scale);
    
    /// Create the cropped image
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage* cropped = [UIImage imageWithCGImage:croppedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(croppedImageRef);
    
    return cropped;
}

/* Convenience method to crop the image from the top left corner */
-(UIImage*)cropToSize_Ext:(CGSize)newSize
{
    return [self cropToSize_Ext:newSize usingMode:ExtCropModeTopLeft];
}

-(UIImage*)scaleByFactor_Ext:(float)scaleFactor
{
    CGSize scaledSize = CGSizeMake(self.size.width * scaleFactor, self.size.height * scaleFactor);
    return [self scaleToFillSize_Ext:scaledSize];
}

-(UIImage*)scaleToSize_Ext:(CGSize)newSize usingMode:(ExtResizeMode)resizeMode
{
    switch (resizeMode)
    {
        case ExtResizeModeAspectFit:
            return [self scaleToFitSize_Ext:newSize];
        case ExtResizeModeAspectFill:
            return [self scaleToCoverSize_Ext:newSize];
        default:
            return [self scaleToFillSize_Ext:newSize];
    }
}

/* Convenience method to scale the image using the ExtResizeModeScaleToFill mode */
-(UIImage*)scaleToSize_Ext:(CGSize)newSize
{
    return [self scaleToFillSize_Ext:newSize];
}

-(UIImage*)scaleToFillSize_Ext:(CGSize)newSize
{
    size_t destWidth = (size_t)(newSize.width * self.scale);
    size_t destHeight = (size_t)(newSize.height * self.scale);
    if (self.imageOrientation == UIImageOrientationLeft
        || self.imageOrientation == UIImageOrientationLeftMirrored
        || self.imageOrientation == UIImageOrientationRight
        || self.imageOrientation == UIImageOrientationRightMirrored)
    {
        size_t temp = destWidth;
        destWidth = destHeight;
        destHeight = temp;
    }
    
    /// Create an ARGB bitmap context
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(destWidth, destHeight, destWidth * kNumberOfComponentsPerARBGPixel_Ext, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    
    UIGraphicsPushContext(bmContext);
    CGContextDrawImage(bmContext, CGRectMake(0.0f, 0.0f, destWidth, destHeight), self.CGImage);
    UIGraphicsPopContext();
    
    /// Create an image object from the context
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(scaledImageRef);
    CGContextRelease(bmContext);
    
    return scaled;
}

-(UIImage*)scaleToFitSize_Ext:(CGSize)newSize
{
    /// Keep aspect ratio
    size_t destWidth, destHeight;
    if (self.size.width > self.size.height)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    else
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    if (destWidth > newSize.width)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    if (destHeight > newSize.height)
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    return [self scaleToFillSize_Ext:CGSizeMake(destWidth, destHeight)];
}

-(UIImage*)scaleToCoverSize_Ext:(CGSize)newSize
{
    size_t destWidth, destHeight;
    CGFloat widthRatio = newSize.width / self.size.width;
    CGFloat heightRatio = newSize.height / self.size.height;
    /// Keep aspect ratio
    if (heightRatio > widthRatio)
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    else
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    return [self scaleToFillSize_Ext:CGSizeMake(destWidth, destHeight)];
}








-(UIImage*)rotateInRadians_Ext:(CGFloat)radians flipOverHorizontalAxis:(BOOL)dohorizontalFlip_Ext verticalAxis:(BOOL)doverticalFlip_Ext
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)CGImageGetWidth(self.CGImage);
    const size_t height = (size_t)CGImageGetHeight(self.CGImage);
    
    CGRect rotatedRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height), CGAffineTransformMakeRotation(radians));
    
    CGContextRef bmContext = CreateARGBBitmapContext_Ext((size_t)rotatedRect.size.width, (size_t)rotatedRect.size.height, (size_t)rotatedRect.size.width * kNumberOfComponentsPerARBGPixel_Ext, YES);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Rotation happen here (around the center)
    CGContextTranslateCTM(bmContext, +(rotatedRect.size.width / 2.0f), +(rotatedRect.size.height / 2.0f));
    CGContextRotateCTM(bmContext, radians);
    
    // Do flips
    CGContextScaleCTM(bmContext, (dohorizontalFlip_Ext ? -1.0f : 1.0f), (doverticalFlip_Ext ? -1.0f : 1.0f));
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, CGRectMake(-(width / 2.0f), -(height / 2.0f), width, height), self.CGImage);
    
    /// Create an image object from the context
    CGImageRef resultImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* resultImage = [UIImage imageWithCGImage:resultImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(resultImageRef);
    CGContextRelease(bmContext);
    
    return resultImage;
}

-(UIImage*)rotateInRadians_Ext:(float)radians
{
    return [self rotateInRadians_Ext:radians flipOverHorizontalAxis:NO verticalAxis:NO];
}

-(UIImage*)rotateInDegrees_Ext:(float)degrees
{
    return [self rotateInRadians_Ext:(float)DEGREES_TO_RADIANS_EXT(degrees)];
}

-(UIImage*)verticalFlip_Ext
{
    return [self rotateInRadians_Ext:0. flipOverHorizontalAxis:NO verticalAxis:YES];
}

-(UIImage*)horizontalFlip_Ext
{
    return [self rotateInRadians_Ext:0. flipOverHorizontalAxis:YES verticalAxis:NO];
}

-(UIImage*)rotateImagePixelsInRadians_Ext:(float)radians
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)(self.size.width * self.scale);
    const size_t height = (size_t)(self.size.height * self.scale);
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, YES);
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {data, height, width, bytesPerRow};
    Pixel_8888 bgColor = {0, 0, 0, 0};
    vImageRotate_ARGB8888(&src, &dest, NULL, radians, bgColor, kvImageBackgroundColorFill);
    
    CGImageRef rotatedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* rotated = [UIImage imageWithCGImage:rotatedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(rotatedImageRef);
    CGContextRelease(bmContext);
    
    return rotated;
}

-(UIImage*)rotateImagePixelsInDegrees_Ext:(float)degrees
{
    return [self rotateImagePixelsInRadians_Ext:(float)DEGREES_TO_RADIANS_EXT(degrees)];
}


-(BOOL)saveToURL_Ext:(NSURL*)url uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor
{
    if (!url)
        return NO;
    
    if (!uti)
        uti = kUTTypePNG;
    
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, uti, 1, NULL);
    if (!dest)
        return NO;
    
    /// Set the options, 1 -> lossless
    CFMutableDictionaryRef options = CFDictionaryCreateMutable(kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (!options)
    {
        CFRelease(dest);
        return NO;
    }
    CFDictionaryAddValue(options, kCGImageDestinationLossyCompressionQuality, (__bridge CFNumberRef)[NSNumber numberWithFloat:1.0f]); // No compression
    if (fillColor)
        CFDictionaryAddValue(options, kCGImageDestinationBackgroundColor, fillColor.CGColor);
    
    /// Add the image
    CGImageDestinationAddImage(dest, self.CGImage, (CFDictionaryRef)options);
    
    /// Write it to the destination
    const bool success = CGImageDestinationFinalize(dest);
    
    /// Cleanup
    CFRelease(options);
    CFRelease(dest);
    
    return success;
}

-(BOOL)saveToURL_Ext:(NSURL*)url type:(ExtImageType)type backgroundFillColor:(UIColor*)fillColor
{
    return [self saveToURL_Ext:url uti:[self utiForType:type] backgroundFillColor:fillColor];
}

-(BOOL)saveToURL_Ext:(NSURL*)url
{
    return [self saveToURL_Ext:url uti:kUTTypePNG backgroundFillColor:nil];
}

-(BOOL)saveToPath_Ext:(NSString*)path uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor
{
    if (!path)
        return NO;
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
    const BOOL ret = [self saveToURL_Ext:url uti:uti backgroundFillColor:fillColor];
    return ret;
}

-(BOOL)saveToPath_Ext:(NSString*)path type:(ExtImageType)type backgroundFillColor:(UIColor*)fillColor
{
    if (!path)
        return NO;
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
    const BOOL ret = [self saveToURL_Ext:url uti:[self utiForType:type] backgroundFillColor:fillColor];
    return ret;
}

-(BOOL)saveToPath_Ext:(NSString*)path
{
    if (!path)
        return NO;
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
    const BOOL ret = [self saveToURL_Ext:url type:ExtImageTypePNG backgroundFillColor:nil];
    return ret;
}

-(BOOL)saveToPhotosAlbum_Ext
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block BOOL ret = YES;
    [library writeImageToSavedPhotosAlbum:self.CGImage orientation:(ALAssetOrientation)self.imageOrientation completionBlock:^(NSURL* assetURL, NSError* error) {
        if (!assetURL)
        {
            NSLog(@"%@", error);
            ret = NO;
        }
    }];
    return ret;
}

+(NSString*)extensionForUTI_Ext:(CFStringRef)uti
{
    if (!uti)
        return nil;
    
    NSDictionary* declarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(uti);
    if (!declarations)
        return nil;
    
    id extensions = [(NSDictionary*)[declarations objectForKey:(__bridge NSString*)kUTTypeTagSpecificationKey] objectForKey:(__bridge NSString*)kUTTagClassFilenameExtension];
    NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? [extensions objectAtIndex:0] : extensions;
    
    return extension;
}

#pragma mark - Private
-(CFStringRef)utiForType:(ExtImageType)type
{
    CFStringRef uti = NULL;
    switch (type)
    {
        case ExtImageTypeBMP:
            uti = kUTTypeBMP;
            break;
        case ExtImageTypeJPEG:
            uti = kUTTypeJPEG;
            break;
        case ExtImageTypePNG:
            uti = kUTTypePNG;
            break;
        case ExtImageTypeTIFF:
            uti = kUTTypeTIFF;
            break;
        case ExtImageTypeGIF:
            uti = kUTTypeGIF;
            break;
        default:
            uti = kUTTypePNG;
            break;
    }
    return uti;
}



-(UIImage*)maskWithImage_Ext:(UIImage*)maskImage
{
    /// Create a bitmap context with valid alpha
    const size_t originalWidth = (size_t)(self.size.width * self.scale);
    const size_t originalHeight = (size_t)(self.size.height * self.scale);
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(originalWidth, originalHeight, 0, YES);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Image mask
    CGImageRef cgMaskImage = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate((size_t)maskImage.size.width, (size_t)maskImage.size.height, CGImageGetBitsPerComponent(cgMaskImage), CGImageGetBitsPerPixel(cgMaskImage), CGImageGetBytesPerRow(cgMaskImage), CGImageGetDataProvider(cgMaskImage), NULL, false);
    
    /// Draw the original image in the bitmap context
    const CGRect r = (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = originalWidth, .size.height = originalHeight};
    CGContextClipToMask(bmContext, r, cgMaskImage);
    CGContextDrawImage(bmContext, r, self.CGImage);
    
    /// Get the CGImage object
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(bmContext);
    /// Apply the mask
    CGImageRef maskedImageRef = CGImageCreateWithMask(imageRefWithAlpha, mask);
    
    UIImage* result = [UIImage imageWithCGImage:maskedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(maskedImageRef);
    CGImageRelease(imageRefWithAlpha);
    CGContextRelease(bmContext);
    CGImageRelease(mask);
    
    return result;
}




///////


-(UIImage*)autoEnhance_Ext
{
    /// No Core Image, return original image
    if (![CIImage class])
        return self;
    
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
    
    NSArray* adjustments = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustRedEye]];
    
    for (CIFilter* filter in adjustments)
    {
        [filter setValue:ciImage forKey:kCIInputImageKey];
        ciImage = filter.outputImage;
    }
    
    CIContext* ctx = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage* final = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return final;
}

-(UIImage*)redEyeCorrection_Ext
{
    /// No Core Image, return original image
    if (![CIImage class])
        return self;
    
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
    
    /// Get the filters and apply them to the image
    NSArray* filters = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustEnhance]];
    for (CIFilter* filter in filters)
    {
        [filter setValue:ciImage forKey:kCIInputImageKey];
        ciImage = filter.outputImage;
    }
    
    /// Create the corrected image
    CIContext* ctx = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage* final = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return final;
}


-(UIImage*)gaussianBlurWithBias_Ext:(NSInteger)bias
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_gaussianblur_kernel_5x5_Ext, 5, 5, 256/*divisor*/, (int32_t)bias, NULL, kvImageCopyInPlace);
    memcpy(data, outt, n);
    free(outt);
    
    CGImageRef blurredImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* blurred = [UIImage imageWithCGImage:blurredImageRef];
    
    /// Cleanup
    CGImageRelease(blurredImageRef);
    CGContextRelease(bmContext);
    
    return blurred;
}






////Filtering

// Value should be in the range (-255, 255)
-(UIImage*)brightenWithValue_Ext:(float)value
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, width * kNumberOfComponentsPerARBGPixel_Ext, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t pixelsCount = width * height;
    float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
    float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
    
    /// Calculate red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Calculate green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Calculate blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
    
    CGImageRef brightenedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* brightened = [UIImage imageWithCGImage:brightenedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(brightenedImageRef);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return brightened;
}

/// (-255, 255)
-(UIImage*)contrastAdjustmentWithValue_Ext:(float)value
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, width * kNumberOfComponentsPerARBGPixel_Ext, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t pixelsCount = width * height;
    float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
    float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
    
    /// Contrast correction factor
    const float factor = (259.0f * (value + 255.0f)) / (255.0f * (259.0f - value));
    
    float v1 = -128.0f, v2 = 128.0f;
    
    /// Calculate red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
    vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Calculate green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
    vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Calculate blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
    vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
    vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
    
    /// Create an image object from the context
    CGImageRef contrastedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* contrasted = [UIImage imageWithCGImage:contrastedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(contrastedImageRef);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return contrasted;
}

-(UIImage*)edgeDetectionWithBias_Ext:(NSInteger)bias
{
#pragma unused(bias)
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    /// vImage (iOS 5) works on simulator but not on device
    /*if ((&vImageConvolveWithBias_ARGB8888))
     {
     const size_t n = sizeof(UInt8) * width * height * 4;
     void* outt = malloc(n);
     vImage_Buffer src = {data, height, width, bytesPerRow};
     vImage_Buffer dest = {outt, height, width, bytesPerRow};
     
     vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_edgedetect_kernel_3x3, 3, 3, 1, bias, NULL, kvImageCopyInPlace);
     
     CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, data, n, NULL);
     
     CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
     CGImageRef edgedImageRef = CGImageCreate(width, height, 8, 32, bytesPerRow, cs, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipFirst, dp, NULL, true, kCGRenderingIntentDefault);
     CGColorSpaceRelease(cs);
     
     //memcpy(data, outt, n);
     //CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
     UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
     
     /// Cleanup
     CGImageRelease(edgedImageRef);
     CGDataProviderRelease(dp);
     free(outt);
     CGContextRelease(bmContext);
     
     return edged;
     }
     else
     {*/
    const size_t pixelsCount = width * height;
    const size_t n = sizeof(float) * pixelsCount;
    float* dataAsFloat = malloc(n);
    float* resultAsFloat = malloc(n);
    float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
    
    /// Red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3_Ext, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3_Ext, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3_Ext, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
    
    CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
    
    /// Cleanup
    CGImageRelease(edgedImageRef);
    free(resultAsFloat);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return edged;
    //}
}

-(UIImage*)embossWithBias_Ext:(NSInteger)bias
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_emboss_kernel_3x3_Ext, 3, 3, 1/*divisor*/, (int32_t)bias, NULL, kvImageCopyInPlace);
    
    memcpy(data, outt, n);
    
    free(outt);
    
    CGImageRef embossImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* emboss = [UIImage imageWithCGImage:embossImageRef];
    
    /// Cleanup
    CGImageRelease(embossImageRef);
    CGContextRelease(bmContext);
    
    return emboss;
}

/// (0.01, 8)
-(UIImage*)gammaCorrectionWithValue_Ext:(float)value
{
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    /// Number of bytes per row, each pixel in the bitmap will be represented by 4 bytes (ARGB), 8 bits of alpha/red/green/blue
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    
    /// Create an ARGB bitmap context
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t pixelsCount = width * height;
    const size_t n = sizeof(float) * pixelsCount;
    float* dataAsFloat = (float*)malloc(n);
    float* temp = (float*)malloc(n);
    float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
    const int iPixels = (int)pixelsCount;
    
    /// Need a vector with same size :(
    vDSP_vfill(&value, temp, 1, pixelsCount);
    
    /// Calculate red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
    vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Calculate green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
    vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Calculate blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
    vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
    
    /// Cleanup
    free(temp);
    free(dataAsFloat);
    
    /// Create an image object from the context
    CGImageRef gammaImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* gamma = [UIImage imageWithCGImage:gammaImageRef];
    
    /// Cleanup
    CGImageRelease(gammaImageRef);
    CGContextRelease(bmContext);
    
    return gamma;
}

-(UIImage*)grayscale_Ext
{
    /* const UInt8 luminance = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722); // Good luminance value */
    /// Create a gray bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, width * kNumberOfComponentsPerGreyPixel_Ext, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, false);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, imageRect, self.CGImage);
    
    /// Create an image object from the context
    CGImageRef grayscaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *grayscaled = [UIImage imageWithCGImage:grayscaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(grayscaledImageRef);
    CGContextRelease(bmContext);
    
    return grayscaled;
}

-(UIImage*)invert_Ext
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, width * kNumberOfComponentsPerARBGPixel_Ext, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t pixelsCount = width * height;
    float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
    float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
    UInt8* dataRed = data + 1;
    UInt8* dataGreen = data + 2;
    UInt8* dataBlue = data + 3;
    
    /// vDSP_vsmsa() = multiply then add
    /// slightly faster than the couple vDSP_vneg() & vDSP_vsadd()
    /// Probably because there are 3 function calls less
    
    /// Calculate red components
    vDSP_vfltu8(dataRed, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsmsa(dataAsFloat, 1, &__ExtNegativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, dataRed, 4, pixelsCount);
    
    /// Calculate green components
    vDSP_vfltu8(dataGreen, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsmsa(dataAsFloat, 1, &__ExtNegativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, dataGreen, 4, pixelsCount);
    
    /// Calculate blue components
    vDSP_vfltu8(dataBlue, 4, dataAsFloat, 1, pixelsCount);
    vDSP_vsmsa(dataAsFloat, 1, &__ExtNegativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
    vDSP_vfixu8(dataAsFloat, 1, dataBlue, 4, pixelsCount);
    
    CGImageRef invertedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* inverted = [UIImage imageWithCGImage:invertedImageRef];
    
    /// Cleanup
    CGImageRelease(invertedImageRef);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return inverted;
}

-(UIImage*)opacity_Ext:(float)value
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, width * kNumberOfComponentsPerARBGPixel_Ext, YES);
    if (!bmContext)
        return nil;
    
    /// Set the alpha value and draw the image in the bitmap context
    CGContextSetAlpha(bmContext, value);
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Create an image object from the context
    CGImageRef transparentImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* transparent = [UIImage imageWithCGImage:transparentImageRef];
    
    /// Cleanup
    CGImageRelease(transparentImageRef);
    CGContextRelease(bmContext);
    
    return transparent;
}

-(UIImage*)sepia_Ext
{
    if ([CIImage class])
    {
        /// The sepia output from Core Image is nicer than manual method and 1.6x faster than vDSP
        CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
        CIImage* output = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey, ciImage, @"inputIntensity", [NSNumber numberWithFloat:1.0f], nil].outputImage;
        CGImageRef cgImage = [GetCIContext_Ext() createCGImage:output fromRect:[output extent]];
        UIImage* sepia = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        return sepia;
    }
    else
    {
        /* 1.6x faster than before */
        /// Create an ARGB bitmap context
        const size_t width = (size_t)self.size.width;
        const size_t height = (size_t)self.size.height;
        CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, width * kNumberOfComponentsPerARBGPixel_Ext, ImageHasAlpha_Ext(self.CGImage));
        if (!bmContext)
            return nil;
        
        /// Draw the image in the bitmap context
        CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
        
        /// Grab the image raw data
        UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
        if (!data)
        {
            CGContextRelease(bmContext);
            return nil;
        }
        
        const size_t pixelsCount = width * height;
        const size_t n = sizeof(float) * pixelsCount;
        float* reds = (float*)malloc(n);
        float* greens = (float*)malloc(n);
        float* blues = (float*)malloc(n);
        float* tmpRed = (float*)malloc(n);
        float* tmpGreen = (float*)malloc(n);
        float* tmpBlue = (float*)malloc(n);
        float* finalRed = (float*)malloc(n);
        float* finalGreen = (float*)malloc(n);
        float* finalBlue = (float*)malloc(n);
        float min = (float)kMinPixelComponentValue_Ext, max = (float)kMaxPixelComponentValue_Ext;
        
        /// Convert byte components to float
        vDSP_vfltu8(data + 1, 4, reds, 1, pixelsCount);
        vDSP_vfltu8(data + 2, 4, greens, 1, pixelsCount);
        vDSP_vfltu8(data + 3, 4, blues, 1, pixelsCount);
        
        /// Calculate red components
        vDSP_vsmul(reds, 1, &__ExtSepiaFactorRedRed, tmpRed, 1, pixelsCount);
        vDSP_vsmul(greens, 1, &__ExtSepiaFactorGreenRed, tmpGreen, 1, pixelsCount);
        vDSP_vsmul(blues, 1, &__ExtSepiaFactorBlueRed, tmpBlue, 1, pixelsCount);
        vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalRed, 1, pixelsCount);
        vDSP_vadd(finalRed, 1, tmpBlue, 1, finalRed, 1, pixelsCount);
        vDSP_vclip(finalRed, 1, &min, &max, finalRed, 1, pixelsCount);
        vDSP_vfixu8(finalRed, 1, data + 1, 4, pixelsCount);
        
        /// Calculate green components
        vDSP_vsmul(reds, 1, &__ExtSepiaFactorRedGreen, tmpRed, 1, pixelsCount);
        vDSP_vsmul(greens, 1, &__ExtSepiaFactorGreenGreen, tmpGreen, 1, pixelsCount);
        vDSP_vsmul(blues, 1, &__ExtSepiaFactorBlueGreen, tmpBlue, 1, pixelsCount);
        vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalGreen, 1, pixelsCount);
        vDSP_vadd(finalGreen, 1, tmpBlue, 1, finalGreen, 1, pixelsCount);
        vDSP_vclip(finalGreen, 1, &min, &max, finalGreen, 1, pixelsCount);
        vDSP_vfixu8(finalGreen, 1, data + 2, 4, pixelsCount);
        
        /// Calculate blue components
        vDSP_vsmul(reds, 1, &__ExtSepiaFactorRedBlue, tmpRed, 1, pixelsCount);
        vDSP_vsmul(greens, 1, &__ExtSepiaFactorGreenBlue, tmpGreen, 1, pixelsCount);
        vDSP_vsmul(blues, 1, &__ExtSepiaFactorBlueBlue, tmpBlue, 1, pixelsCount);
        vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalBlue, 1, pixelsCount);
        vDSP_vadd(finalBlue, 1, tmpBlue, 1, finalBlue, 1, pixelsCount);
        vDSP_vclip(finalBlue, 1, &min, &max, finalBlue, 1, pixelsCount);
        vDSP_vfixu8(finalBlue, 1, data + 3, 4, pixelsCount);
        
        /// Create an image object from the context
        CGImageRef sepiaImageRef = CGBitmapContextCreateImage(bmContext);
        UIImage* sepia = [UIImage imageWithCGImage:sepiaImageRef];
        
        /// Cleanup
        CGImageRelease(sepiaImageRef);
        free(reds), free(greens), free(blues), free(tmpRed), free(tmpGreen), free(tmpBlue), free(finalRed), free(finalGreen), free(finalBlue);
        CGContextRelease(bmContext);
        
        return sepia;
    }
}

-(UIImage*)sharpenWithBias_Ext:(NSInteger)bias
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_sharpen_kernel_3x3_Ext, 3, 3, 1/*divisor*/, (int32_t)bias, NULL, kvImageCopyInPlace);
    
    memcpy(data, outt, n);
    
    free(outt);
    
    CGImageRef sharpenedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* sharpened = [UIImage imageWithCGImage:sharpenedImageRef];
    
    /// Cleanup
    CGImageRelease(sharpenedImageRef);
    CGContextRelease(bmContext);
    
    return sharpened;
}

-(UIImage*)unsharpenWithBias_Ext:(NSInteger)bias
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)self.size.width;
    const size_t height = (size_t)self.size.height;
    const size_t bytesPerRow = width * kNumberOfComponentsPerARBGPixel_Ext;
    CGContextRef bmContext = CreateARGBBitmapContext_Ext(width, height, bytesPerRow, ImageHasAlpha_Ext(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    /// Grab the image raw data
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_unsharpen_kernel_3x3_Ext, 3, 3, 9/*divisor*/, (int32_t)bias, NULL, kvImageCopyInPlace);
    
    memcpy(data, outt, n);
    
    free(outt);
    
    CGImageRef unsharpenedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* unsharpened = [UIImage imageWithCGImage:unsharpenedImageRef];
    
    /// Cleanup
    CGImageRelease(unsharpenedImageRef);
    CGContextRelease(bmContext);
    
    return unsharpened;
}

static unsigned char morphological_kernel_Ext[9] = {
    1, 1, 1,
    1, 1, 1,
    1, 1, 1,
};

- (UIImage *)erode_Ext
{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
        return nil;
    
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    
    vImageErode_ARGB8888(&src, &dest, 0, 0, morphological_kernel_Ext, 3, 3, kvImageCopyInPlace);
    
    memcpy(data, outt, n);
    
    free(outt);
    
    CGImageRef erodedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* eroded = [UIImage imageWithCGImage:erodedImageRef];
    
    CGImageRelease(erodedImageRef);
    CGContextRelease(bmContext);
    
    return eroded;
}

- (UIImage *)erodeWithIterations_Ext:(int)iterations
{
    
    UIImage *dstImage = self;
    iterations=MAX(1, iterations);
    
    for (int i=0; i<iterations; i++) {
        dstImage = [dstImage erode_Ext];
    }
    return dstImage;
}


- (UIImage *)dilate_Ext
{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
        return nil;
    
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageDilate_ARGB8888(&src, &dest, 0, 0, morphological_kernel_Ext, 3, 3, kvImageCopyInPlace);
    
    memcpy(data, outt, n);
    
    free(outt);
    
    CGImageRef dilatedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* dilated = [UIImage imageWithCGImage:dilatedImageRef];
    
    CGImageRelease(dilatedImageRef);
    CGContextRelease(bmContext);
    
    return dilated;
}

- (UIImage *)dilateWithIterations_Ext:(int)iterations
{
    
    UIImage *dstImage = self;
    iterations=MAX(1, iterations);
    for (int i=0; i<iterations; i++) {
        dstImage = [dstImage dilate_Ext];
    }
    return dstImage;
}


- (UIImage *)gradientWithIterations_Ext:(int)iterations {
    
    iterations=MAX(1, iterations);
    
    UIImage *dilated = [self dilateWithIterations_Ext:iterations];
    UIImage *eroded = [self erodeWithIterations_Ext:iterations];
    
    UIImage *dstImage = [dilated imageBlendedWithImage_Ext:eroded blendMode:kCGBlendModeDifference alpha:1.0];
    
    return dstImage;
}


- (UIImage *)tophatWithIterations_Ext:(int)iterations
{
    iterations=MAX(1, iterations);
    
    UIImage *dilated = [self dilateWithIterations_Ext:iterations];
    
    UIImage *dstImage = [self imageBlendedWithImage_Ext:dilated blendMode:kCGBlendModeDifference alpha:1.0];
    
    return dstImage;
}

- (UIImage *)blackhatWithIterations_Ext:(int)iterations
{
    iterations=MAX(1, iterations);
    
    UIImage *eroded = [self erodeWithIterations_Ext:iterations];
    
    UIImage *dstImage = [eroded imageBlendedWithImage_Ext:self blendMode:kCGBlendModeDifference alpha:1.0];
    
    return dstImage;
}



- (UIImage *)imageBlendedWithImage_Ext:(UIImage *)overlayImage blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha {
    
    UIGraphicsBeginImageContext(self.size);
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [self drawInRect:rect];
    
    [overlayImage drawAtPoint:CGPointMake(0, 0) blendMode:blendMode alpha:alpha];
    
    UIImage *blendedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return blendedImage;
}


- (UIImage *)equalization_Ext
{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
        return nil;
    
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {data, height, width, bytesPerRow};
    
    vImageEqualization_ARGB8888(&src, &dest, kvImageNoFlags);
    
    CGImageRef destImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* destImage = [UIImage imageWithCGImage:destImageRef];
    
    CGImageRelease(destImageRef);
    CGContextRelease(bmContext);
    
    return destImage;
}

@end
