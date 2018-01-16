//
//  Utils.m
//  FaceTrackerSdk
//
//  Created by My Star on 12/22/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import "Utils.h"

@implementation Util
cv::Point findDropPoint(cv::Point top, cv::Point B,cv::Point C){
    
    
    int x1=B.x;
    int y1=B.y;
    int x2=C.x;
    int y2=C.y;
    int x3=top.x;
    int y3=top.y;
    float a= y1-y2;
    float b=-(x1-x2);
    float c=x1*y2-y1*x2;
    float dist=a*a+b*b;
    float x=(b*(b*x3-a*y3)-a*c)/dist;
    float y=(a*(-b*x3+a*y3)-b*c)/dist;
    
    return cv::Point(x,y);
}
@end
