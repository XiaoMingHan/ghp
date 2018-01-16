//
//  HKDrawFacialPointsFilter.m
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import "HKDrawFacialPointsFilter.h"
#import "PointShader.h"
#import "HKTracker.h"
static float greenColor[] = { 0.0, 1.0, 0.0, 1.0 };
static float yellowColor[] = { 1.0, 1.0, 0.0, 1.0 };

@interface HKDrawFacialPointsFilter(){
    PointShader *shader;
};
@end

@implementation HKDrawFacialPointsFilter
-(id)init{
      shader=[PointShader new];
    id res=[super initWithShader:shader];
    glGenBuffers( 1, &_vertexBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData( GL_ARRAY_BUFFER,VERTEX_NUMBER*sizeof(Vertex), (GLvoid *)vertex, GL_STATIC_DRAW );
    
    
    glGenBuffers( 1, &_indexBuffer);
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexBuffer );
    glBufferData( GL_ELEMENT_ARRAY_BUFFER, INDICES_NUMBER*sizeof(VertexIndices), (GLvoid *)Indices, GL_STATIC_DRAW );
   
    return res;
}
-(void)update{
    if(Tracker.isTracked==YES){
    for (int i=0;i<68;i++){
        vertex[i].Position[0]= Tracker.Facelandmark[i].x;
        vertex[i].Position[1]= Tracker.Facelandmark[i].y;
        vertex[i].Position[2]= 0.0;
    }
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData( GL_ARRAY_BUFFER,VERTEX_NUMBER*sizeof(Vertex), (GLvoid *)vertex, GL_STATIC_DRAW );
    }
}
-(void)renderWithProjection:(GLKMatrix4)_p{
    
  //  if(Tracker.isTracked){
    
    GLKMatrix4 mvp = _p;
    [shader use];
    [shader setModelViewProjection:mvp.m];
    [shader setPointColor:greenColor];
    [shader setPointSize:6.];

    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
    glEnableVertexAttribArray( GLKVertexAttribPosition );
    glVertexAttribPointer( GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)0 );
    glDrawArrays( GL_POINTS, 0, VERTEX_NUMBER);
    
    
//    [shader setPointColor:yellowColor];
//    [shader setAlpha:0.56];
//    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexBuffer );
//   // glDrawElements( GL_LINE_STRIP, INDICES_NUMBER, GL_UNSIGNED_SHORT, 0 );
//    for ( int i = 0; i < INDICES_NUMBER ; i++ )
//    {
//        glDrawElements( GL_TRIANGLE_STRIP, 3, GL_UNSIGNED_SHORT, (void *)(i * 3 * sizeof( unsigned short )) );
//
//    }

  //  [_pointShader setPointColor:yellowColor];
  //  glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexBuffer );
    [shader unuse];
 //   }
}
@end
