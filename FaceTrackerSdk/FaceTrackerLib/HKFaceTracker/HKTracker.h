//
//  DlibWrapper.h
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import "Utils.h"
#import <CoreMedia/CoreMedia.h>

#define Tracker  HKTracker.sharedInstance
@interface HKTracker : NSObject

- (instancetype)init;
+ (HKTracker *)sharedInstance;
- (void)prepare;
- (void)predetectingFace:(NSArray<NSValue *> *)rects image:(CMSampleBufferRef)sampleBuffer;
- (CGRect)getFaceRect;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)trackingHeadMask:(CVImageBufferRef)imageBuffer inRects:(NSArray<NSValue *> *)rects;
@property std::vector<cv::Point>Facelandmark;
@property std::vector<cv::Point3d>Face3dpos;
@property BOOL isTracked;
@property GLKMatrix4 _m;
-(BOOL)findFaceLandMark:(UIImage*)image;
-(NSMutableArray*)getFaceBoundFormImage:(UIImage*)image;
-(void)drawFacialPoint:(CMSampleBufferRef)sampleBuffer;
@end
