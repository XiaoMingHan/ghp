//
//  HKCamera.h
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

#import "GLSLShader.h"
#define YUV_CAMERA 0
#define METADATA   0
#define FRAMERATE  60


//#define Camera     CameraManager.sharedInstance



@protocol HKCameraDelegate <NSObject>

- (void)processImageBuffer:(CVImageBufferRef)frame;

@end


@interface HKCamera:NSObject {
    
    AVCaptureSession *_session;
    AVCaptureConnection *_videoConnection;
    AVCaptureVideoDataOutput *_videoOutput;
    /**
     * Reference to the previously captured and cached texture. Released whenever a new frame is
     * captured by the camera.
     */
    CVOpenGLESTextureRef _cvTexture0;
    CVOpenGLESTextureRef _cvTexture1;
    
    /**
     * Automatically takes care of creating enough textures for cached textures of the captured
     * camera images.
     */
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    dispatch_queue_t _serialMetadataQueue;
    BOOL smileFlag;
    BOOL enable_Detecting;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _texCoordsBuffer;
    CGRect m_rect;
}

@property (nonatomic) dispatch_queue_t serialSessionQueue;
@property BOOL smileFlag;
@property BOOL enable_Detecting;
@property (assign, nonatomic) BOOL initialized;
@property (assign, nonatomic) GLKMatrix4 projection;

@property (nonatomic, strong) AVCaptureDevice *camera;
@property (nonatomic, strong) GLSLShader *videoShader;
@property (nonatomic, assign) CVOpenGLESTextureRef cvTexture0;
@property (nonatomic, weak) id<HKCameraDelegate> delegate;

+ (HKCamera *)sharedInstance;
-(void)MakeExample:(NSString*) makeFileName;
- (AVCaptureDevicePosition)getCameraPos;
- (void )deleteCamera;
- (CGSize)frameSize;
- (AVCaptureDevicePosition)getCameraFrontDevice;
- (void)setupAVCaptureWithCamera:(AVCaptureDevicePosition)position;
- (void)stopAVCapture;
-(void)startAVCapture;
- (AVCaptureDevicePosition)swapCamera;
- (void)SetFaceRect:(CGRect)rect;
- (void)Destroy;
- (BOOL)isFlash;
-(AVCaptureDevice*)GetCamera;
@end

