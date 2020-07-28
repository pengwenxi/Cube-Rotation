//
//  ViewController.m
//  GLKitView正方体旋转
//
//  Created by 彭文喜 on 2020/7/27.
//  Copyright © 2020 彭文喜. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;  //顶点坐标
    GLKVector2 textureCoord;   //纹理坐标
    GLKVector3 normal;         //法线
}Vertex;

//顶点数
static NSInteger const kCoordCount = 36;

@interface ViewController ()<GLKViewDelegate>

@property(nonatomic,strong)GLKView *glkView;
@property(nonatomic,strong)GLKBaseEffect *baseEffect;
@property(nonatomic,assign)Vertex *vertices;

@property(nonatomic,strong)CADisplayLink *displayLink;
@property(nonatomic,assign)NSInteger angle;
@property(nonatomic,assign)GLuint vertexBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    [self commonInit];
    
    [self addCADisplayLink];
    
}

-(void)addCADisplayLink{
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)commonInit{
    //1、创建context
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    //设置当前的context
    [EAGLContext setCurrentContext:context];
    
    //2、创建GLKView并设置代理
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc]initWithFrame:frame context:context];

    self.glkView.backgroundColor = UIColor.clearColor;
    self.glkView.delegate = self;
    
    //3、使用深度缓存
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    //默认是（0，1），这里用于翻转z轴，使正方形朝屏幕外
    glDepthRangef(1, 0);
    
    //4、将GLKView添加self.view上
    [self.view addSubview:self.glkView];
    
    //5、获取纹理图片
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fengjing.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];

    //6、设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft:@(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:NULL];
    
    //7、使用baseEffect
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    //开启光照效果
    self.baseEffect.light0.enabled = YES;
    //漫反射颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    //光源位置
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
    
    /*
    解释一下:
    这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点
    以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
    */
    
    //8. 开辟顶点数据空间(数据结构SenceVertex 大小 * 顶点个数kCoordCount)
    
    self.vertices = malloc(sizeof(Vertex)*kCoordCount);
    
    // 前面
    self.vertices[0] = (Vertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
    self.vertices[1] = (Vertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertices[2] = (Vertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertices[3] = (Vertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertices[4] = (Vertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertices[5] = (Vertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};
    
    // 上面
    self.vertices[6] = (Vertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
    self.vertices[7] = (Vertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertices[8] = (Vertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertices[9] = (Vertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertices[10] = (Vertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertices[11] = (Vertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};
    
    // 下面
    self.vertices[12] = (Vertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
    self.vertices[13] = (Vertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertices[14] = (Vertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertices[15] = (Vertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertices[16] = (Vertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertices[17] = (Vertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};
    
    // 左面
    self.vertices[18] = (Vertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
    self.vertices[19] = (Vertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertices[20] = (Vertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertices[21] = (Vertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertices[22] = (Vertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertices[23] = (Vertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};
    
    // 右面
    self.vertices[24] = (Vertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
    self.vertices[25] = (Vertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertices[26] = (Vertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertices[27] = (Vertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertices[28] = (Vertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertices[29] = (Vertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};
    
    // 后面
    self.vertices[30] = (Vertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
    self.vertices[31] = (Vertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertices[32] = (Vertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertices[33] = (Vertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertices[34] = (Vertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertices[35] = (Vertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};
    
    //开启顶点缓冲区
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(Vertex) * kCoordCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    //加载顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, positionCoord));
    
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, textureCoord));
    
    //加载法线数据
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, normal));
    
}
#pragma mark - GLKViewDelegate
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    //1、开启深度测试
    glEnable(GL_DEPTH_TEST);
    //2、清除颜色缓冲区&深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    //3、准备绘制
    [self.baseEffect prepareToDraw];
    //4、绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}

-(void)update{
    //1、计算旋转度数
    self.angle = (self.angle+2)%360;
    //2、修改baseEffect.transform.modelviewMatrix
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.5, 0.4, 0.8);
    //3、重新渲染
    [self.glkView display];
}

-(void)dealloc{
    if([EAGLContext currentContext] == self.glkView.context){
        [EAGLContext setCurrentContext:nil];
    }
    if(_vertices){
        free(_vertices);
        _vertices = nil;
    }
    [self.displayLink invalidate];
}
@end
