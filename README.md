# Cube-Rotation
# OpenGL ES案例 - 立方体贴图旋转

这篇博客我们来实现一个立方体旋转的效果动画，利用OpenGL ES来完成。
最终效果图如下：

![QQ20200728-185531-HD](media/15959334492369/QQ20200728-185531-HD.gif)

在本案例中，我们使用GLKView视图和GLKBaseEffect着色器去实现这样的功能。

下面先介绍一下GLKView和GLKBaseEffect的一些常用的方法和属性。
###GLKView
1、初始化视图
- initWithFrame:context: 初始化新视图
2、配置帧缓冲区对象
- drawableColorFormat 颜⾊色渲染缓存区格式
- drawableDepthFormat 深度渲染缓存区格式
- drawableStencilFormat 模板渲染缓存区的格式
- drawableMultisample 多重采样缓存区的格式
3、帧缓冲区属性
- drawableHeight 底层缓存区对象的高度(以像素为单位)
- drawableWidth 底层缓存区对象的宽度(以像素为单位)
4、代理
- delegate 视图的代理理

在我们使用GLKView去绘制视图内容时，也有一些属性需要我们自己去设定：
- context 绘制视图内容时使⽤用的OpenGL ES 上下⽂文
- bindDrawable 将底层FrameBuffer 对象绑定到OpenGL ES
- enableSetNeedsDisplay 布尔值,指定视图是否响应使得视图内容无效的消息
- display ⽴即重绘视图内容
- snapshot 绘制视图内容并将其作为新图像对象返回

当我们不需要视图对象时，我们也可以删除对象
- deleteDrawable 删除与视图关联的可绘制对象

而我们使用GLKView时，必须使用它的代理方法对实现视图内容的绘制
- glkView:drawInRect: 绘制视图内容


###GLKBaseEffect
GLKBaseEffect是一种简单的光照/着色系统。
我们也可以根据GLKBaseEffect的一些属性和方法去设置模型视图：
1、使用transform绑定效果时应⽤于顶点数据的模型视图,投影和纹理变换
2、lightingType ⽤用于计算每个片段的光照策略略
3、配置光照light0场景中第⼀个光照属性，light1，light2
4、配置纹理texture2d0第⼀个纹理理属性，texture2d1，textureOrder纹理理应⽤用于渲染图元的顺序
5、- prepareToDraw 准备渲染效果


下面我们开始介绍案例的实现：
绘制立方体，我们需要计算立方体的顶点，而在OpenGL中，所有图形都是通过点、线、三角形去绘制的，因此在绘制立方体六个面中，需要12个三角形，因此需要36个顶点，因此我们利用一个结构体去表示顶点坐标和纹理坐标与法线

```
typedef struct {
    GLKVector3 positionCoord;  //顶点坐标
    GLKVector2 textureCoord;   //纹理坐标
    GLKVector3 normal;         //法线
}Vertex;
static NSInteger const kCoordCount = 36;
```

至于顶点坐标，下面我会把代码贴出来，感兴趣的同学可以去研究一下他的坐标：

```
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
    
```

立方体的坐标解决了，那么就只需要初始化GLKView和GLKBaseEffect了，下面贴出关键代码
```
//首先创建context
 EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
 //设置context
 [EAGLContext setCurrentContext:context];
 
 self.glkView = [[GLKView alloc]initWithFrame:frame context:context];
 self.glkView.delegate = self;
 //深度缓存
 self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;

 //纹理的设置
 //设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft:@(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:NULL];

//使用baseEffect配置纹理
self.baseEffect.texture2d0.name = textureInfo.name;
self.baseEffect.texture2d0.target = textureInfo.target;

//开启灯照效果，在正对我们的面光亮显示
self.baseEffect.light0.enabled = YES;
self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
//光源位置
self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
```

在对GLKBaseEffect配置玩纹理后，我们需要开启顶点缓冲区，将存入在内存中的顶点坐标加载到显存中，而顶点的缓冲区默认是关闭的，我们需要将它开启，否则将不起作用

```
glGenBuffers(1, &_vertexBuffer);
glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
GLsizeiptr bufferSizeBytes = sizeof(Vertex) * kCoordCount;
glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
```

开启缓冲区后，我们还需要加载顶点、纹理、法线等数据
```
//加载顶点数据
glEnableVertexAttribArray(GLKVertexAttribPosition);
glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, positionCoord));
    
glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, textureCoord));
    
//加载法线数据
glEnableVertexAttribArray(GLKVertexAttribNormal);
glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL+offsetof(Vertex, normal));
```
在上面的代码中：
第一个参数指定要修改的顶点属性的索引值
第二个参数指定顶点属性大小。
第三个参数指定数据类型。
第四个参数定义是否希望数据被标准化（归一化），只表示方向不表示大小。
第五个参数是步长（Stride），指定在连续的顶点属性之间的间隔。上面传0和传4效果相同，如果传1取值方式为0123、1234、2345……
第六个参数表示我们的位置数据在缓冲区起始位置的偏移量

因为我们是利用结构体去设置顶点的属性，因此定义步长时，可以加载结构体的大小，而最后一个参数NULL可以省略不写，offsetof表示结构体属性的大小。

设置上面的属性，基本上可以显示图像，但是如何让他旋转呢？
我们这边使用CADisplayLink定时器去不断的更改角度和重新渲染

代码:
```
self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    -(void)update{
    //1、计算旋转度数
    self.angle = (self.angle+2)%360;
    //2、修改baseEffect.transform.modelviewMatrix
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.5, 0.4, 0.8);
    //3、重新渲染
    [self.glkView display];
}
```

最后，我在上面说过，要绘制图像，必须利用GLKView的代理方法去实现

```
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
```

整个过程就是如此，实现这个功能的还有很多方法，在iOS中还可以使用CoreAnimation去实现，有兴趣的同学可以自己去了解。



