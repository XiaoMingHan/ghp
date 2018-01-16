//
//  HKCamera.m
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import "HKCamera.h"
#import "HKCamera+Renderer.h"
#import <GLKit/GLKit.h>
#import <sys/utsname.h>
#import <Accelerate/Accelerate.h>
#include <OpenCV2/OpenCV.hpp>
#import  "HKTracker.h"
BOOL _highPerformanceDevice = YES;

static HKCamera *_sharedInstance;
@interface HKCamera () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate> {
    
    dispatch_group_t _group;
    NSString *make_example_fileName;
    BOOL make_example_enable;
    NSArray * currentMetadata;
}
@end



@implementation HKCamera
@synthesize smileFlag,enable_Detecting;

#pragma mark - Singleton

+ (HKCamera *)sharedInstance
{
    
    if ( !_sharedInstance )
    {
        _sharedInstance = [HKCamera new];
    }
    return _sharedInstance;
}

- (void )deleteCamera
{
    
    _sharedInstance=nil;
}

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        struct utsname systemInfo;
        
        uname( &systemInfo );
        NSLog( @"Device model: %s", systemInfo.machine );
        
        if ( !strncmp( systemInfo.machine, "iPhone", 6 ) )
        {
            int version = systemInfo.machine[ 6 ] - 48;
            if ( version <= 5 )
            {
                _highPerformanceDevice = NO;
            }
        }
        if ( !strncmp( systemInfo.machine, "iPad", 4 ) )
        {
            int version = systemInfo.machine[ 4 ] - 48;
            if ( version <= 2 )
            {
                _highPerformanceDevice = NO;
            }
        }
        
        _serialMetadataQueue = dispatch_queue_create( "com.nga.GLFace.serialMetadataQueue", DISPATCH_QUEUE_SERIAL );
        _serialSessionQueue = dispatch_queue_create( "com.nga.GLFace.serialSessionQueue", DISPATCH_QUEUE_SERIAL );
        dispatch_queue_t high = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 );
        dispatch_set_target_queue( _serialSessionQueue, high );
        
        
        
        
        _group = dispatch_group_create();
        _projection = GLKMatrix4Identity;
        enable_Detecting=NO;
        [Tracker prepare];
        
    }
    return self;
}


- (void)dealloc
{
    [self tearDown];
    [self stopAVCapture];
    // [Camera deleteCamera];
}

- (void)Destroy{
    [self tearDown];
    [self stopAVCapture];
    _initialized=NO;
}
-(void)MakeExample:(NSString*) makeFileName{
    make_example_fileName=makeFileName;
    make_example_enable=YES;
}
- (AVCaptureDevicePosition)swapCamera
{
    AVCaptureDevicePosition position;
    
    AVCaptureDeviceInput *oldInput = _session.inputs[ 0 ];
    position = oldInput.device.position;
    [self setupAVCaptureWithCamera:position == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack:AVCaptureDevicePositionFront];
    
    return position;
}
-(AVCaptureDevice*)GetCamera{
    if ( _session.inputs.count )
    {
        
        AVCaptureDeviceInput *oldInput = _session.inputs[ 0 ];
        return oldInput.device;
    }
    return nil;
}
-(BOOL)isFlash{
    AVCaptureDeviceInput *oldInput = _session.inputs[ 0 ];
    return [oldInput.device hasFlash];
}
-(AVCaptureDevicePosition)getCameraFrontDevice{
    if ( _session.inputs.count )
    {
        AVCaptureDeviceInput *oldInput = _session.inputs[ 0 ];
        AVCaptureDevicePosition position = oldInput.device.position;
        return position;
    }
    return AVCaptureDevicePositionUnspecified;
}

#pragma mark Camera setup

-(AVCaptureDevicePosition)getCameraPos{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *device = nil;
    AVCaptureDevicePosition res = AVCaptureDevicePositionBack;
    for ( AVCaptureDevice *dev in devices )
    {
        if ( [dev position] == AVCaptureDevicePositionFront )
        {
            device = dev;
            res=AVCaptureDevicePositionFront;
            break;
        }
    }
    return res;
}
- (AVCaptureDevice *)cameraByPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevice *device = nil;
    
    for ( AVCaptureDevice *dev in devices )
    {
        if ( [dev position] == position )
        {
            device = dev;
            break;
        }
    }
    if ( device )
    {
        if ( [device.activeFormat videoSupportedFrameRateRanges] )
        {
            [self attemptToConfigureCamera:device toFPS:FRAMERATE];
        }
        
        if ( [ device lockForConfiguration:nil] )
        {
            if ( device.focusPointOfInterestSupported )
            {
                device.focusPointOfInterest = CGPointMake( .5, .5 );     // CENTER
            }
            if ( device.isLowLightBoostSupported )
            {
                device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            }
            if ( [device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance] )
            {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device setVideoZoomFactor:1];
            [device unlockForConfiguration];
        }
    }
    return device;
}

-(void)flashTurnoffon:(BOOL) flg{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn])
    {
        BOOL success = [flashLight lockForConfiguration:nil];
        if (success)
        {
            if ([flashLight isTorchActive] && flg==NO)
            {
                
                [flashLight setTorchMode:AVCaptureTorchModeOff];
            }
            else if( flg==YES)
            {
                
                [flashLight setTorchMode:AVCaptureTorchModeOn];
            }
            [flashLight unlockForConfiguration];
        }
    }
    
}

- (void)stopAVCapture
{
    
    dispatch_async( _serialSessionQueue, ^() {
        if ( _session.isRunning )
        {
            [_session stopRunning];
        }
        _session = nil;
        [self tearDown];
    } );
}
-(void)startAVCapture{
    dispatch_async( _serialSessionQueue, ^() {
        if(!_session.isRunning){
            [_session startRunning];
        }
    } );
    
}


- (CGSize)frameSize
{
    //  return CGSizeMake( 288, 352 );
    return CGSizeMake( 480, 640 );
}


- (void)setupAVCaptureWithCamera:(AVCaptureDevicePosition)position
{
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    //[_session setSessionPreset:AVCaptureSessionPreset352x288];
    [_session setSessionPreset:AVCaptureSessionPreset640x480];
    
    AVCaptureDevice *videoDevice = [self cameraByPosition:position];
    if ( videoDevice == nil )
    {
        return;
    }
    
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( error )
    {
        return;
    }
    
    [_session addInput:input];
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    
#if defined YUV_CAMERA && YUV_CAMERA > 0
    [_videoOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) }];
#else
    [_videoOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) }];
#endif
    
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [_session addOutput:_videoOutput];
    
    
    
    
    
    // set portrait orientation
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    _videoConnection.automaticallyAdjustsVideoMirroring = NO;
    if ( _videoConnection.supportsVideoMirroring )
    {
        _videoConnection.videoMirrored = position == AVCaptureDevicePositionFront;
    }
   
    
  

    // Metadata output
    AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
    [metadataOutput setMetadataObjectsDelegate:self queue:_serialMetadataQueue];
    if ( [_session canAddOutput:metadataOutput] )
    {
        [_session addOutput:metadataOutput];
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }

    dispatch_async( _serialSessionQueue, ^() {
        [_session commitConfiguration];
        [_session startRunning];
    } );
    
}
- (void)SetFaceRect:(CGRect)rect{
    m_rect=rect;
}
#pragma mark Video capture

#define FourCC2Str( code ) (char[5]) { (code >> 24) & 0xFF, (code >> 16) & 0xFF, (code >> 8) & 0xFF, code & 0xFF, 0 }

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    
    

    static int xxx=0;
    [self updateFrame:pixelBuffer];
    xxx++;
    if(xxx%2==0){
         [self trackingFace:captureOutput PixelBuffer:pixelBuffer];
    }
    
    
//    if ( !dispatch_group_wait( _group, DISPATCH_TIME_NOW ) )
//    {
//        CVBufferRetain( pixelBuffer );
//        dispatch_group_async( _group, _serialSessionQueue, ^{
//            xxx=0;
//
//
//
//
//            CVBufferRelease( pixelBuffer );
//        } );
//
//
//
//    }
    
  
}

-(void)trackingFace:(AVCaptureOutput *)captureOutput PixelBuffer:(CVImageBufferRef)imageBuffer{
    if (currentMetadata){
        if(currentMetadata.count>0){
            
            NSMutableArray* array=[NSMutableArray new];
            for ( AVMetadataObject *object in currentMetadata )
            {
                
                if ( [[object type] isEqual:AVMetadataObjectTypeFace] )
                {
                    CGRect faceBounds = CGRectZero;
                    faceBounds  = [captureOutput rectForMetadataOutputRectOfInterest:object.bounds];
                    [array addObject:[NSValue valueWithCGRect:faceBounds]];
                    
                }
            }
            if (array.count>0){

              
                [Tracker trackingHeadMask:imageBuffer inRects:array];
                Tracker.isTracked=YES;
                currentMetadata=nil;
                
            }else{
               
            }
        }
    }else{
        Tracker.isTracked=NO;
    }
}

#pragma mark Metadata capture


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
     currentMetadata=metadataObjects;
}


#pragma mark - Utilities

- (void)attemptToConfigureCamera:(AVCaptureDevice *)device toFPS:(int)desiredFrameRate
{
    NSError *error;
    
    if ( ![device lockForConfiguration:&error] )
    {
        NSLog( @"Could not lock device %@ for configuration: %@", device, error );
        return;
    }
    
    AVCaptureDeviceFormat *format = device.activeFormat;
    double epsilon = 0.00000001;
    
    for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges )
    {
        
        if ( range.minFrameRate <= (desiredFrameRate + epsilon) &&
            range.maxFrameRate >= (desiredFrameRate - epsilon))
        {
            device.activeVideoMaxFrameDuration = (CMTime) {
                .value = 1,
                .timescale = desiredFrameRate,
                .flags = kCMTimeFlags_Valid,
                .epoch = 0,
            };
            device.activeVideoMinFrameDuration = (CMTime) {
                .value = 1,
                .timescale = desiredFrameRate,
                .flags = kCMTimeFlags_Valid,
                .epoch = 0,
            };
            break;
        }
    }
    
    [device unlockForConfiguration];
}


@end

