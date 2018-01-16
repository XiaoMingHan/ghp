//
//  DlibWrapper.m
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import "HKTracker.h"
#import <UIKit/UIKit.h>
#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/opencv.h>
#import "MySpline.h"

@interface HKTracker (){
     std::vector<int> colorCurve;
}

@property (assign) BOOL prepared;

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end
static HKTracker *_sharedInstance;
@implementation HKTracker {
    dlib::shape_predictor sp;
    dlib::frontal_face_detector detector;
    CIDetector *faceDetector;
    std::vector<cv::Point3d>model_points;
    CGRect m_rect;

}
@synthesize  Facelandmark,_m,Face3dpos,isTracked;

- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}
+ (HKTracker *)sharedInstance
{
    
    if ( !_sharedInstance )
    {
        _sharedInstance = [HKTracker new];
    }
    return _sharedInstance;
}
- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];

  //  NSString *location = [[NSBundle mainBundle] resourcePath];

    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
  //  NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh }; // TODO: read doc for more tuneups
    faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
   
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
    
    model_points.push_back(cv::Point3d(-34, 90, 83));//l eye (Interpupillary breadth)
    model_points.push_back(cv::Point3d(34, 90, 83));//r eye (Interpupillary breadth)
    model_points.push_back(cv::Point3d(0.0, 50, 120));//nose (Nose top)
    model_points.push_back(cv::Point3d(-26, 15, 83));//l mouse (Mouth breadth)
    model_points.push_back(cv::Point3d(26, 15, 83));//r mouse (Mouth breadth)
    model_points.push_back(cv::Point3d(-79, 90, 0.0));//l ear (Bitragion breadth)
    model_points.push_back(cv::Point3d(79, 90, 0.0));//r ear (Bitragion breadth)
    
    
    
    
    MySpline *spline = [[MySpline alloc] init:65];

    [spline addPoint:cv::Point(0,0)];
    [spline addPoint:cv::Point(127,250)];
    [spline addPoint:cv::Point(255,255)];
    std::vector<cv::Point> colorArray=[spline getSplinePoints];
    colorArray.push_back( cv::Point(255,255));
    

    for(int x=0;x<=255;x++){
        colorCurve.push_back( getCurveColor(colorArray, x));
    }
}

//
//
//-(BOOL)oneImageProcessing:(cv::Mat)image{
//    
//   
//
//    if (!self.prepared) {
//        [self prepare];
//    }
//    
//    dlib::array2d<dlib::bgr_pixel> img;
//    cv::cvtColor(image, image, CV_RGBA2BGR);
//    dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(image));
//
//    
//  
//    
//
//    cv::Mat frame_gray;
//    
//    cvtColor( image, frame_gray, CV_BGR2GRAY );
//    equalizeHist( frame_gray, frame_gray );
// 
//    //-- Detect faces
//  
//    std::vector<cv::Rect> faces;
//    classifier.detectMultiScale(frame_gray, faces, 1.2, 2, CV_HAAR_SCALE_IMAGE, cv::Size(250, 250));
//
//    
//    
//    // convert the face bounds list to dlib format
//
//    std::vector<cv::Point> temp;
//    // for every detected face
//
//    for (unsigned long j = 0; j < faces.size(); ++j)
//    {
//        // detect all landmarks
//        dlib::full_object_detection shape = sp(img, dlib::rectangle(faces[j].x,faces[j].y,faces[j].x+faces[j].width,faces[j].y+faces[j].height));
//        
//        // and draw them into the image (samplebuffer)
//        for (unsigned long k = 0; k < shape.num_parts(); k++) {
//            dlib::point p = shape.part(k);
//            temp.push_back(cv::Point((int)p.x(),(int)p.y()));
//            // draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
//        }
//    }
//    facelandmark=temp;
//    return YES;
// }
int getCurveColor(std::vector<cv::Point>  colors , int val){
    cv::Point res;
    for (int i=0;i<colors.size()-1;i++){
        if(colors[i+1].x==colors[i].x)continue;
        if(colors[i].x<=val && val<=colors[i+1].x){
            res=  colors[i]+1.0*(colors[i+1]-colors[i])*(colors[i+1].x-val)/(colors[i+1].x-colors[i].x);
            if(res.y>255)res=cv::Point(res.x,255);
            if(res.y<0)res=cv::Point(res.x,0);
            break;
        }
    }
    return res.y;
}
- (void)predetectingFace:(NSArray<NSValue *> *)rects image:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // MARK: magic
    
    //CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGPoint center=CGPointMake(height/2, width/2);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGRect rect=[[rects objectAtIndex:0] CGRectValue];
    m_rect=CGRectMake(rect.origin.y-center.x,rect.origin.x-center.y,rect.size.height,rect.size.width);
}
- (CGRect)getFaceRect{
    return m_rect;//;.origin.x,m_rect.origin.y,m_rect.size.width,m_rect.size.height);
}
-(NSMutableArray*)getFaceBoundFormImage:(UIImage*)image{
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [faceDetector featuresInImage:ciImage options:nil];
    NSMutableArray *returnBounds = [NSMutableArray array];
    
    for (CIFeature *feature in features) {
        CGRect faceRect=[feature bounds];
        faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height;
        [returnBounds addObject:[NSValue valueWithCGRect:faceRect]];
    }
    return returnBounds;
}
-(BOOL)findFaceLandMark:(UIImage*)image{
    
    
    
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [faceDetector featuresInImage:ciImage options:nil];
    NSMutableArray *returnBounds = [NSMutableArray array];
    
    for (CIFeature *feature in features) {
        CGRect faceRect=[feature bounds];
        faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height;
        [returnBounds addObject:[NSValue valueWithCGRect:faceRect]];
    }

    if([features count]==0)return NO;

      [ self doWorkOnPixelBuffer:[self pixelBufferFromCGImage:image.CGImage] inRects:returnBounds];
    return YES;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    

    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
   
    [ self doWorkOnPixelBuffer:imageBuffer inRects:rects];
        
    
  
}

-(void)drawFacialPoint:(CMSampleBufferRef)sampleBuffer {
     CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    
    //CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    
    // set_size expects rows, cols format
    img.set_size(height, width);
    
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        position++;
    }
     CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    for (unsigned long k = 0; k < facelandmark.size(); k++){
//        dlib::point p =dlib::point(facelandmark[k].x,facelandmark[k].y);
//        
//        draw_solid_circle(img, p, 10, dlib::rgb_pixel(255, 0, 0));
//    }
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
        img.reset();
        position = 0;
        while (img.move_next()) {
            dlib::bgr_pixel& pixel = img.element();
    
            // assuming bgra format here
            long bufferLocation = position * 4; //(row * width + column) * 4;
            baseBuffer[bufferLocation] = pixel.blue;
            baseBuffer[bufferLocation + 1] = pixel.green;
            baseBuffer[bufferLocation + 2] = pixel.red;
            //        we do not need this
            //        char a = baseBuffer[bufferLocation + 3];
    
            position++;
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)trackingHeadMask:(CVImageBufferRef)imageBuffer inRects:(NSArray<NSValue *> *)rects {
    [self doWorkOnPixelBuffer:imageBuffer inRects:rects];
    
    std::vector<cv::Point2d> image_points;
    
    image_points.push_back(cv::Point((Facelandmark[38].x + Facelandmark[41].x) / 2, (Facelandmark[38].y + Facelandmark[41].y) / 2));//l eye (Interpupillary breadth)
    
    image_points.push_back(cv::Point((Facelandmark [43].x + Facelandmark [46].x) / 2, (Facelandmark [43].y + Facelandmark [46].y) / 2));//r eye (Interpupillary breadth)
    image_points.push_back(cv::Point(Facelandmark[30].x, Facelandmark[30].y));//nose (Nose top)
    image_points.push_back(cv::Point(Facelandmark [48].x, Facelandmark [48].y));//l mouth (Mouth breadth)
    image_points.push_back(cv::Point(Facelandmark [54].x, Facelandmark [54].y)); //r mouth (Mouth breadth)
    image_points.push_back(cv::Point(Facelandmark [0].x, Facelandmark [0].y));//l ear (Bitragion breadth)
    image_points.push_back(cv::Point(Facelandmark [16].x, Facelandmark [16].y));//r ear (Bitragion breadth)
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    double focal_length = width;
    cv::Point center = cv::Point((int)width/2,(int)height/2);
    cv::Mat camera_matrix = (cv::Mat_<double>(3,3) << focal_length, 0, center.x, 0 , focal_length, center.y, 0, 0, 1);
    cv::Mat dist_coeffs = cv::Mat::zeros(4,1,cv::DataType<double>::type); // Assuming no lens distortion
    cv::Mat rotation_vector; // Rotation in axis-angle form
    cv::Mat translation_vector;
    
    
    // Solve for pose
    cv::solvePnP(model_points, image_points, camera_matrix, dist_coeffs, rotation_vector, translation_vector);
    
    std::vector<cv::Point2d> nose_end_point2D;
    
    cv::projectPoints(model_points, rotation_vector, translation_vector, camera_matrix, dist_coeffs, nose_end_point2D);
    
    //Fix the model's coordination
    
    
    //***************************
    
    
    cv::Matx33d rotation;
    cv::Rodrigues(rotation_vector, rotation);
    GLKMatrix4 transformM ={
            (float)rotation(0,0),    (float)rotation(0,1),    (float)rotation(0,2),    (float)translation_vector.at<double>(0)/1000,
            (float)rotation(1,0),    (float)rotation(1,1),    (float)rotation(1,2),   (float)translation_vector.at<double>(1)/1000,
            (float)rotation(2,0),    (float)rotation(2,1),    (float)rotation(2,2),    (float)translation_vector.at<double>(2)/1000,
            0,                0,                0,                     1
    };
    _m=transformM;
//
//    cv::Mat tvec = (cv::Mat_<double>(3,1) << 0., 0., 1000.);
//    cv::Mat rvec = (cv::Mat_<double>(3,1) << 1.2, 1.2, -1.2);
//    cv::Mat projectionMat = cv::Mat::zeros(3,3,CV_32F);
//    cv::Matx33f projection = projectionMat;
//    // Find the 3D pose of our head
//    cv::solvePnP(model_points, image_points,  projection,dist_coeffs,rvec, tvec, true,  cv::SOLVEPNP_ITERATIVE);
//
////    std::vector<cv::Point> nose_end_point2D;
////    cv::projectPoints(model_points, rvec, tvec, projection, dist_coeffs, nose_end_point2D);
//
//    cv::Matx33d rotation;
//    cv::Rodrigues(rvec, rotation);
//
//    cv::Matx44f transformM(
//        rotation(0,0),    rotation(0,1),    rotation(0,2),    tvec.at<double>(0)/1000,
//        rotation(1,0),    rotation(1,1),    rotation(1,2),    tvec.at<double>(1)/1000,
//        rotation(2,0),    rotation(2,1),    rotation(2,2),    tvec.at<double>(2)/1000,
//        0,                0,                0,                     1
//    );
//
//
//
//    cv::Matx34d P(
//               rotation(0,0),    rotation(0,1),    rotation(0,2),    tvec.at<double>(0)/1000,
//               rotation(1,0),    rotation(1,1),    rotation(1,2),    tvec.at<double>(1)/1000,
//               rotation(2,0),    rotation(2,1),    rotation(2,2),    tvec.at<double>(2)/1000
//               );
//    cv::Mat KP = camera_matrix * cv::Mat(P);
//    for (int i=0; i<model_points.size(); i++) {
//        cv::Mat_<double> X = (cv::Mat_<double>(4,1) << model_points[i].x,model_points[i].y,model_points[i].z,1.0);
//        //        cout << "object point " << X << endl;
//        cv::Mat_<double> opt_p = KP * X;
//        cv::Point2f opt_p_img(opt_p(0)/opt_p(2),opt_p(1)/opt_p(2));
//        float delX=image_points[i].x-opt_p_img.x;
//        float delY=image_points[i].y-opt_p_img.y;
//
//        //        cout << "object point reproj " << opt_p_img << endl;
//
//      //  circle(img, opt_p_img, 4, cv::Scalar(0,0,255), 1);
//    }
}
- (void)doWorkOnPixelBuffer:(CVImageBufferRef)imageBuffer inRects:(NSArray<NSValue *> *)rects {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
//
//    // MARK: magic
//
//    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
//   // CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
//
//
//    // set_size expects rows, cols format
//    img.set_size(height, width);
//
//    // copy samplebuffer image data into dlib image format
//    img.reset();
//    long position = 0;
//    while (img.move_next()) {
//        dlib::bgr_pixel& pixel = img.element();
//
//        // assuming bgra format here
//        long bufferLocation = position * 4; //(row * width + column) * 4;
//        char b = baseBuffer[bufferLocation];
//        char g = baseBuffer[bufferLocation + 1];
//        char r = baseBuffer[bufferLocation + 2];
//
//        dlib::bgr_pixel newpixel(b, g, r);
//        pixel = newpixel;
//
//        position++;
//    }
//
//    // unlock buffer again until we need it again
//     CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
  //   CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    float fact=0.6;
    
    cv::Mat imgMat=[self parseBuffer:imageBuffer];
    cv::Mat gray;
    cv::cvtColor(imgMat, gray, CV_BGRA2GRAY);
    int height=imgMat.rows;
    int width=imgMat.cols;
    cv::cvtColor(gray, imgMat, CV_GRAY2BGR);
   // curvesColorChange(imgMat,colorCurve);
    cv::resize(imgMat, imgMat,cv::Size(width*fact, height*fact));
    dlib::assign_image(img, dlib::cv_image<dlib::bgr_pixel>(imgMat));
    
    
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [HKTracker convertCGRectValueArray:rects fact:fact];
    
    
    
    
    std::vector<cv::Point>temp;
    // for every detected face
    for (unsigned long j = 0; j <1; ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            temp.push_back(cv::Point((int)p.x()/fact,(int)p.y()/fact));
          // draw_solid_circle(img, p, 10, dlib::rgb_pixel(255, 0, 0));
        }
    }
    Facelandmark=temp;
}
void curvesColorChange(cv::Mat &face,std::vector<int> curve){
    
    

    
    
    
    
    for (int x = 0; x < face.cols; x++)
    {
        for (int y = 0; y < face.rows; y++)
        {
            
            int R = cv::saturate_cast<uchar>((face.at<cv::Vec3b>(y, x)[0]));
            int G = cv::saturate_cast<uchar>((face.at<cv::Vec3b>(y, x)[1]));
            int B = cv::saturate_cast<uchar>((face.at<cv::Vec3b>(y, x)[2]));
            
            
            int Rval=(R+G+B)/3;
            
            int Rcon=curve[Rval];
            
            float Rcolor=1.0*Rcon/Rval;
            if(Rval==0)Rcolor=0.0;
            int  RR = R*Rcolor;
            int  GG = G*Rcolor;
            int  BB = B*Rcolor;
            RR=MAX(MIN(RR,255),0);
            GG=MAX(MIN(GG,255),0);
            BB=MAX(MIN(BB,255),0);
            face.at<cv::Vec3b>(y, x)[0] = RR;
            face.at<cv::Vec3b>(y, x)[1] = GG;
            face.at<cv::Vec3b>(y, x)[2] = BB;
            
            
            
        }
    }
    
    
    
}
- (cv::Mat ) parseBuffer:(CVImageBufferRef) pixelBuffer
{
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    //Processing here
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // put buffer in open cv, no memory copied
    cv::Mat mat = cv::Mat(bufferHeight,bufferWidth,CV_8UC4,pixel);
    
    //End processing
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    return mat;
    
}
+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects fact:(float)rate{
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x*rate;
        long top = rect.origin.y*rate;
        long right = left + rect.size.width*rate;
        long bottom = top + rect.size.height*rate;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGAffineTransform frameTransform=CGAffineTransformMakeRotation(0);
    CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
