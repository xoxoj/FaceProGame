//
//  HeadDecorationNode.m
//  face plus
//
//  Created by linxudong on 1/16/15.
//  Copyright (c) 2015 Willian. All rights reserved.
//
#import "AccessoryNode.h"
#import "AccessoryShadow.h"
#import "Pixel2Point.h"
#import "FaceNode.h"
#import "SKSceneCache.h"
#import "MyScene.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation AccessoryNode
@synthesize curPosition,curAngle;
@synthesize curScaleFactor;

//不许直接调用，要经过initwithentity
-(instancetype) initWithImageNamed:(NSString *)name{
    //SKTextureAtlas * main=[SKTextureAtlas atlasNamed:sucaiAtlas ];
    self=[super initWithImageNamed:name];
    if (self!=nil) {
        self.name= accessoryLayerName;
        self.zPosition=121;
        self.tag=@"部件";
        self.blendMode=SKBlendModeAlpha;
        self.anchorPoint=CGPointMake(0.5, 0.5);
        self.order=12;//素材列表位置
        self.selectedPriority=13;
        self.currentImageFile=name;
        
      
    }
    return self;
}
-(instancetype) initWithEntity:(BaseEntity *)entity{
    self=[self initWithImageNamed:entity.selfFileName];
    if (entity.selfShadowFileName) {
        //添加阴影
        AccessoryShadow* shadow=[[AccessoryShadow alloc]initWithImageNamed:entity.selfShadowFileName];
        shadow.size=self.size;
        [self addChild:shadow];
    }
    if (self) {
        AccessoryRecordObject*object=[[AccessoryRecordObject alloc]initWithNodeAndImageFile:self currentEntity:entity];
        NSDictionary*dict=[NSDictionary dictionaryWithObject:object forKey:@"RECORD_OBJECT"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ADD_RECORDS_OF_ACCESSORY" object:self userInfo:dict];
    }
    self.currentEntity=entity;
[self calculateExifWithFileName:entity.selfFileName];
    return self;
}

-(void)setSize:(CGSize)size{
    [super setSize:size];
    AccessoryShadow*shadow=(AccessoryShadow*)[self childNodeWithName:accessoryShadowLayerName];
    [shadow setSize:size];
}

-(void)drag:(NSValue*)dest{
    
    //获得的值是方向相反所以用减法
    CGPoint finalPosition=CGPointMake(self.curPosition.x+dest.CGPointValue.x/6,self.curPosition.y-dest.CGPointValue.y/6 );
    [self setPosition:finalPosition];
    
}

//不需要切换素材，只有存在或不存在两个状态
-(BOOL)changeTexture:(BaseEntity *)entity{
//    //重要，写入
//    self.currentImageFile=entity.selfFileName;
//    SKTexture* texture=[SKTexture textureWithImageNamed:entity.selfFileName];
//    self.texture=texture;
//    CGSize size=[Pixel2Point pixel2point:texture.size];
//    self.size=size;
    return YES;
}

-(void)zoom:(NSNumber*)scaleFactor{
    [self setScale:scaleFactor.floatValue*self.curScaleFactor];
}
-(void)color:(UIColor *)color{
    self.color=color;
}
//不带png后缀的参数
-(void)calculateExifWithFileName:(NSString*)imageName{
    
    
    CGSize faceTextureSize;
    FaceNode*faceNode= (FaceNode*)  [[SKSceneCache singleton].scene childNodeWithName:faceLayerName];
    
    faceTextureSize=[Pixel2Point pixel2point:((FaceNode*)faceNode).texture.size];
    
    //读取exif数据
    NSString* actualName=[NSString stringWithFormat:@"%@%@",[imageName stringByReplacingOccurrencesOfString:@".png" withString:@""],@"@2x~iphone"];
    NSString*path= [[NSBundle mainBundle] pathForResource:actualName ofType:@"png"];
    //说明是推送的素材来自update文件夹
    if (path==nil)
    {
        path=imageName;
    }
    NSURL* url=[NSURL fileURLWithPath:path];
    
    
  
    BOOL isUP=YES;
    NSString*scaleAndAnchor= [(NSDictionary*)[[CIImage imageWithContentsOfURL:url].properties objectForKey:@"{TIFF}"] objectForKey:@"Software"] ;
    CGFloat scaleData=1.0;
    CGPoint anchorData=CGPointMake(0.5, 1.0);
    
    NSArray*tempColorStringArray = [scaleAndAnchor componentsSeparatedByString:@"%"];
    NSString*colorString=@"0x000000";
    if (tempColorStringArray.count>1) {
        colorString=tempColorStringArray[1];
        scaleAndAnchor=tempColorStringArray[0];
    }
    int number = (int)strtol(colorString.UTF8String, NULL, 0);
    self.color=UIColorFromRGB(number);
    
    
    if (scaleAndAnchor) {
        isUP=[[scaleAndAnchor componentsSeparatedByString:@"~"][0] intValue];
        
        NSString*anchorString=[[scaleAndAnchor componentsSeparatedByString:@"~"][1]componentsSeparatedByString:@":"][0] ;
        anchorData=CGPointMake(
                               [[anchorString componentsSeparatedByString:@","][0] floatValue],
                               [[anchorString componentsSeparatedByString:@","][1] floatValue]
                               );
        
        scaleData=[[[scaleAndAnchor componentsSeparatedByString:@"~"][1]componentsSeparatedByString:@":"][1] floatValue];
    }
    
    if (!isUP) {
        //SKAction *moveDown=[SKAction moveBy:CGVectorMake(0, -faceTextureSize.height) duration:0];
        [self setPosition:CGPointMake(0, -faceTextureSize.height)];
    }
    
    CGSize size=[Pixel2Point pixel2point:self.texture.size];
    
    self.size=CGSizeMake(size.width*scaleData, size.height*scaleData);
    self.position=CGPointMake(self.position.x+size.width*anchorData.x,self.position.y+ size.height*anchorData.y);
    
}


-(void)setAnchorPoint:(CGPoint)anchorPoint{

    [super setAnchorPoint:anchorPoint];
    AccessoryShadow*shadow=(AccessoryShadow*)[self childNodeWithName:accessoryShadowLayerName];
    [shadow setAnchorPoint:anchorPoint];
}

-(void)calculateExif:(BaseEntity*)entity{
    NSString*imageFileWithOutExtension=  [entity.selfFileName stringByReplacingOccurrencesOfString:@".png" withString:@""];
    [self calculateExifWithFileName:imageFileWithOutExtension];
}

-(void)rotateMyself:(NSNumber*)angle{
    [self setZRotation:self.curAngle+angle.floatValue];
}
@end
