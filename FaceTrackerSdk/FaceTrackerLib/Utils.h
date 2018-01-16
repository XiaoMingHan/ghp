//
//  Utils.h
//  FaceTrackerSdk
//
//  Created by My Star on 12/22/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <OpenCV2/OpenCV.hpp>
#define Utils  Util.sharedInstance
@interface Util : NSObject
cv::Point findDropPoint(cv::Point top, cv::Point B,cv::Point C);
@end
