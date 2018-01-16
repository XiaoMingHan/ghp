//
//  HKRenderer.h
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <OpenCV2/OpenCV.hpp>
#import "GLSLShader.h"
#define VERTEX_NUMBER 68
#define INDICES_NUMBER 104
typedef struct {
    int p1;
    int p2;
    int p3;
    int p4;
}VertexIndex;
typedef struct {
    float Position[3];//4x3
    float TexCoord[2];//4x2
    
}Vertex;
typedef struct {
    unsigned short i;
    unsigned short j;
    unsigned short k;
    
}VertexIndices;
typedef enum{
    ANIMATIONFILTER,
    D3MASKFILTER,
    IMAGEFILTER,
}FILTER_TYPE;

typedef enum{
    
    BROW_LEFT,
    BROW_RIGHT,
    HORN_LEFT,
    HORN_RIGHT,
    EYE_LEFT,
    EYE_RIGHT,
    NOSE,
    MOUTH,
    EYES,
    
}FACE_TYPE;
@interface HKBaseFilter : NSObject{
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    VertexIndices Indices[INDICES_NUMBER];
    GLSLShader *m_shader;
    int meshCount;
    
}

-(id)initWithShader:(GLSLShader*)shader;
-(void)update;
-(void)renderWithProjection:(GLKMatrix4) _p;
@end
