//
//  MySpline.m
//  FaceAR_SDK_IOS_OpenFace_RunFull
//
//  Created by My Star on 12/26/16.
//  Copyright © 2016 Keegan Ren. All rights reserved.
//

#import "MySpline.h"

@implementation MySpline {
    
    NSMutableArray* ControlPointsX;
    NSMutableArray* ControlPointsY;
    NSMutableArray* Colors;
    
}

- (id) init:(int)segment;
{
    self = [super init];
    if (self != NULL) {
        _points = 0;
        _segments = segment;
        _tension = 0;
        _bias = 0;
        _continuity = 0;
        _interpolateColor = true;
        _width = 1.0;
        ControlPointsX = [[NSMutableArray alloc] init];
        ControlPointsY = [[NSMutableArray alloc] init];
        Colors = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void) addPoint:(cv::Point)pt{
    [self addPointWithX:pt.x Y:pt.y];
}
- (void) addPointWithX: (double) x
                     Y: (double) y {
    [ControlPointsX addObject:[NSNumber numberWithDouble:x]];
    [ControlPointsY addObject:[NSNumber numberWithDouble:y]];

    _points++;
}

- (std::vector<cv::Point>) getSplinePoints
{
    double x, nextX, prevX;
    double y, nextY, prevY;

    NSMutableArray* DSvectorsX = [[NSMutableArray alloc] init];
    NSMutableArray* DSvectorsY = [[NSMutableArray alloc] init];
    NSMutableArray* DDvectorsX = [[NSMutableArray alloc] init];
    NSMutableArray* DDvectorsY = [[NSMutableArray alloc] init];
   // NSMutableArray* res =[[NSMutableArray alloc] init];
    // If sufficient points have been specified...
    std::vector<cv::Point> res;
    if (_points>1) {
        // Discipline naughty data
        if (_segments<=0) _segments = 1;
        
      
        // Calculate incoming and outgoing tangent vectors
        // for each point (Kochanek and Bartels Equations 8 & 9)
        for(int i = 0; i<_points; i++) {
            x = [[ControlPointsX objectAtIndex:i] doubleValue];
            y = [[ControlPointsY objectAtIndex:i] doubleValue];
            // End point handling: setting imaginary
            // points the same as the start and end points.
            if (i == 0) {
                nextX = [[ControlPointsX objectAtIndex:i+1] doubleValue];
                nextY = [[ControlPointsY objectAtIndex:i+1] doubleValue];
                prevX = [[ControlPointsX objectAtIndex:i] doubleValue];
                prevY = [[ControlPointsY objectAtIndex:i] doubleValue];
            }
            else if (i == _points-1) {
                nextX = [[ControlPointsX objectAtIndex:i] doubleValue];
                nextY = [[ControlPointsY objectAtIndex:i] doubleValue];
                prevX = [[ControlPointsX objectAtIndex:i-1] doubleValue];
                prevY = [[ControlPointsY objectAtIndex:i-1] doubleValue];
            }
            else {
                nextX = [[ControlPointsX objectAtIndex:i+1] doubleValue];
                nextY = [[ControlPointsY objectAtIndex:i+1] doubleValue];
                prevX = [[ControlPointsX objectAtIndex:i-1] doubleValue];
                prevY = [[ControlPointsY objectAtIndex:i-1] doubleValue];
            }
            // tension/continuity/bias equations
            double d0a = ((1-_tension)*(1-_continuity)*(1+_bias))/2;
            double d0b = ((1-_tension)*(1+_continuity)*(1-_bias))/2;
            double d1a = ((1-_tension)*(1+_continuity)*(1+_bias))/2;
            double d1b = ((1-_tension)*(1-_continuity)*(1-_bias))/2;
            // DS "source derivative" (incoming vector) for this point
            [DSvectorsX addObject:[NSNumber numberWithDouble:d0a*(x-prevX) + d0b*(nextX-x)]];
            [DSvectorsY addObject:[NSNumber numberWithDouble:d0a*(y-prevY) + d0b*(nextY-y)]];
            // DD "desination derivative" (outgoing vector) for this point
            [DDvectorsX addObject:[NSNumber numberWithDouble:d1a*(x-prevX) + d1b*(nextX-x)]];
            [DDvectorsY addObject:[NSNumber numberWithDouble:d1a*(y-prevY) + d1b*(nextY-y)]];
        }
   
            for(int i = 0; i<_points-1; i++) {
            x = [[ControlPointsX objectAtIndex:i] doubleValue];
            y = [[ControlPointsY objectAtIndex:i] doubleValue];
            nextX = [[ControlPointsX objectAtIndex:i+1] doubleValue];
            nextY = [[ControlPointsY objectAtIndex:i+1] doubleValue];
            // Retrieve DDi (derivative of outgoing vector for point i)
            double xd0 = [[DDvectorsX objectAtIndex:i] doubleValue];
            double yd0 = [[DDvectorsY objectAtIndex:i] doubleValue];
            // Retrieve DSi+1 (derivative of incoming vector for point i+1)
            double xd1 = [[DSvectorsX objectAtIndex:i+1] doubleValue];
            double yd1 = [[DSvectorsY objectAtIndex:i+1] doubleValue];
            // Apply the matrix
            // (Kochanek and Bartels Equation 2, h*C)
            double ax, bx, cx, dx;
            double ay, by, cy, dy;
            // For x
            ax = 2.0*x - 2.0*nextX + xd0 + xd1;
            bx = -3.0*x + 3.0*nextX - 2.0*xd0 - xd1;
            cx = xd0;
            dx = x;
            // For y
            ay = 2.0*y - 2.0*nextY + yd0 + yd1;
            by = -3.0*y + 3.0*nextY - 2.0*yd0 - yd1;
            cy = yd0;
            dy = y;
                
           // Draw the segments
            double s=0, s2=0, s3=0;
            double increment = 1.0/(_segments-1);
            for (int j = 0; j<_segments; j++) {
                // A tiny bit of time saving
                if (s!=0) {
                    s2 = s*s; // squared
                    s3 = s2*s; // cubed
                }
                               //And set vertex
                CGPoint point=CGPointMake(( ax*s3 + bx*s2 + cx*s + dx),(ay*s3 + by*s2 + cy*s + dy));
                res.push_back(cv::Point(point.x,point.y));         
                s=s+increment;
            }
        }
        
    }
    return res;
}

@end
