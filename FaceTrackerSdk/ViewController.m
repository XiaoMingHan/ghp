//
//  ViewController.m
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import "ViewController.h"
#import "HKScene.h"
@interface ViewController ()<GLKViewDelegate>
{
    HKScene *scene;
    CADisplayLink *_displayLink;
}
@property (weak, nonatomic) IBOutlet GLKView *glkView;
@end

@implementation ViewController

- (void)viewDidLoad {
    

    scene = [[HKScene alloc] initWithView:(GLKView *)self.glkView ];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _glkView.enableSetNeedsDisplay = NO;
    
    _glkView.delegate = self;
}
-(void)viewWillAppear:(BOOL)animated{
    if ( !_displayLink )
    {
        
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        
        _displayLink.frameInterval = 60 / FRAMERATE;
        
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }

}
-(void)viewDidAppear:(BOOL)animated{
    
    HKCamera*  camera=[HKCamera new];
    [camera setupAVCaptureWithCamera:AVCaptureDevicePositionFront];
    [scene addCamera:camera];
    [scene setupWithView:self.glkView];
    
 
}
- (void)viewWillDisappear:(BOOL)animated{
    if ( _displayLink )
    {
        
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink invalidate];
        _displayLink = nil;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)render:(CADisplayLink *)displayLink
{
    dispatch_async( dispatch_get_main_queue(), ^() {
        
        [self update];
        
    } );
    
    [scene update];
    
    [_glkView display];
    
    
 
    
    
}
- (void)update
{
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    void (^renderBlock)( BOOL, float ) = ^( BOOL flipped, float scale ){
        [scene render];
    };
    
    renderBlock( NO, view.contentScaleFactor );
    
    
}
@end
