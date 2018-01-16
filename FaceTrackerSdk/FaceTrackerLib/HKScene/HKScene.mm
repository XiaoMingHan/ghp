//
//  FSMScene.m
//  MoodMe
//
// Copyright (c) 2015 MoodMe (http://www.mood-me.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "HKScene.h"
#import <AVFoundation/AVFoundation.h>

#import "HKCamera+Renderer.h"
#import "HKDrawFacialPointsFilter.h"
@interface HKScene () {

    EAGLContext *_context;


    
    HKCamera *Camera;
    BOOL camera_only;
    BOOL setMaking_Example;
    dispatch_group_t _group;
    dispatch_queue_t _serialMetadataQueue;
    GLKMatrix4 _projectionMatrix;
    
    GLuint _colorRenderBuffer;
    CAEAGLLayer *_eaglLayer;
    GLuint depthBuffer;
    GLuint framebuffer;
    GLuint m_defaultFBOName;
    HKDrawFacialPointsFilter *featurePoints;
}

@end


@implementation HKScene


#pragma mark -
#pragma mark Lifecycle
GLuint m_colorRenderbuffer;
GLuint m_depthRenderbuffer;

- (instancetype)initWithView:(GLKView *)view
{
    setMaking_Example=NO;
    self = [super init];
    if ( self )
    {
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if ( !_context )
        {
            NSLog( @"Failed to create ES context" );
        }
         [ self setupWithView:view];
         if(camera_only==NO){
       

        }
        _serialMetadataQueue = dispatch_queue_create( "com.nga.GLFace.serialMetadataQueue", DISPATCH_QUEUE_SERIAL );
      //  _serialSessionQueue = dispatch_queue_create( "com.nga.GLFace.serialSessionQueue", DISPATCH_QUEUE_SERIAL );
      //  dispatch_queue_t high = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 );
       // dispatch_set_target_queue( _serialSessionQueue, high );
        _group = dispatch_group_create();
 
        featurePoints=[[HKDrawFacialPointsFilter alloc] init];

    }
    return self;
}
-(void)appendFilter:(NSMutableArray*)filterArray{
    

    
}
-(void)addCamera:(HKCamera*)camera{
    Camera=camera;
}
- (void)setupWithView:(GLKView *)view
{
    

    [EAGLContext setCurrentContext:_context];
    view.context=_context;

    float width  = Camera.frameSize.width;
    float height = Camera.frameSize.height;

    _projectionMatrix = GLKMatrix4MakeOrtho( 0, width, height, 0, 600, -600 );

      [Camera setProjection:_projectionMatrix];
    
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    
    glEnable( GL_CULL_FACE );
    glCullFace( GL_FRONT_AND_BACK );
    glClearDepthf(1.0f);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

}

- (void)dealloc
{
    [self tearDown];
}

-(void)selectFilter:(int)filter{
    
 //    if ( !dispatch_group_wait( _group, DISPATCH_TIME_NOW ) )
//    {
//       
//        dispatch_group_async( _group, Camera.serialSessionQueue, ^{
//            
//        
//        } );
//    }
 
  

}
#pragma mark -
#pragma mark Cleanup


- (void)tearDown
{
    [EAGLContext setCurrentContext:_context];

    if ( [EAGLContext currentContext] == _context )
    {
        [EAGLContext setCurrentContext:nil];
    }
}


- (void)reset
{
  
}


#pragma mark -
#pragma mark Rendering


- (void)update
{
    
    [featurePoints update];
   // [_animRender update];
}


- (void)render
{
    [EAGLContext setCurrentContext:_context];
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    [featurePoints renderWithProjection:_projectionMatrix];

    glClearColor(0.0, 0.0, 0.0, 1.0);
    [Camera render];

}


@end
