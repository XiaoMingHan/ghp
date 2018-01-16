//
//  MySpline.h
//  FaceAR_SDK_IOS_OpenFace_RunFull
//
//  Created by My Star on 12/26/16.
//  Copyright © 2016 Keegan Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#include <opencv2/imgproc.hpp>
@interface MySpline : NSObject

@property   double   segments; // number of lines to use to construct the spline between two points
// Strictly speaking, tension, bias and continuity should be between -1 and 1.
// However, interesting things can happen outside of those ranges,
// so the code doesn't enforce the standard range.
// If all three are set to 0, the result is a Catmull-Rom spline.
@property   double   tension;// -1.0 to 1.0  round <-> tight
@property   double   continuity; // -1.0 to 1.0  box corners <-> inverted corners
@property   double   bias; // -1.0 to 1.0  pre-shoot <-> post-shoot
@property   double   width;
@property   bool     interpolateColor;
@property  (readonly)   UInt32  points;

- (id) init:(int)segment;

- (void) addPointWithX: (double) x
                     Y: (double) y;

- (void) addPoint:(cv::Point)pt;
- (std::vector<cv::Point>) getSplinePoints;

@end
