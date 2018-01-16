//
//  HKRenderer.m
//  FaceTrackerSdk
//
//  Created by My Star on 12/20/17.
//  Copyright © 2017 My Star. All rights reserved.
//

#import "HKBaseFilter.h"

@implementation HKBaseFilter
unsigned short _skinIndices[] = {
    58,67,59,
    60,49,48,
    58,59,6,
    34,52,35,
    44,45,25,
    39,40,29,
    37,18,36,
    27,42,22,
    23,44,24,
    41,36,1,
    50,62,51,
    57,58,7,
    28,27,39,
    52,34,51,
    54,14,35,
    29,42,28,
    19,20,24,
    35,15,46,
    37,19,18,
    36,0,1,
    18,17,36,
    37,20,19,
    38,20,37,
    21,20,38,
    21,38,39,
    24,44,25,
    30,34,35,
    21,39,27,
    28,42,27,
    39,29,28,
    29,30,35,
    31,30,29,
    30,33,34,
    31,29,40,
    36,17,0,
    41,31,40,
    31,32,30,
    31,41,1,
    49,31,48,
    48,2,3,
    67,60,59,
    4,48,3,
    5,48,4,
    6,59,5,
    59,48,5,
    60,48,59,
    7,58,6,
    61,49,60,
    58,66,67,
    31,2,48,
    31,50,32,
    1,2,31,
    61,50,49,
    52,62,63,
    50,31,49,
    34,33,51,
    51,62,52,
    32,50,51,
    50,61,62,
    63,53,52,
    54,55,11,
    57,8,9,
    66,58,57,
    8,57,7,
    56,57,9,
    66,57,56,
    10,56,9,
    55,56,10,
    53,54,35,
    53,35,52,
    12,54,11,
    55,10,11,
    65,56,55,
    66,65,56,
    64,55,54,
    65,55,64,
    54,53,64,
    64,53,63,
    12,13,54,
    14,54,13,
    15,35,14,
    47,35,46,
    33,32,51,
    30,32,33,
    29,35,47,
    15,45,46,
    22,21,27,
    20,21,23,
    43,23,22,
    29,47,42,
    23,21,22,
    24,20,23,
    22,42,43,
    23,43,44,
    45,16,26,
    15,16,45,
    25,45,26,
    60,61,67,
    61,67,62,
    62,67,66,
    62,67,66,
    62,66,63,
    63,66,65,
    63,65,64
};


-(id)initWithShader:(GLSLShader*)shader{
    if(!m_shader)m_shader =shader;
 
    for (int index=0;index<INDICES_NUMBER;index++){
        Indices[index].i=_skinIndices[index*3];
        Indices[index].j=_skinIndices[index*3+1];
        Indices[index].k=_skinIndices[index*3+2];
      
    }
    return [super init];
}
-(void)update{
  
    
}
-(void)renderWithProjection:(GLKMatrix4) _p
{
 
}
-(void)destory{
    [m_shader destory];
    glDeleteBuffers( 1, &_vertexBuffer );
    glDeleteBuffers( 1, &_indexBuffer );

}
@end