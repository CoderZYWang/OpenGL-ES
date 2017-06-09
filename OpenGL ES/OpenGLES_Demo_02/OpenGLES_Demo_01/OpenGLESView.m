//
//  OpenGLESView.m
//  OpenGLES_Demo_01
//
//  Created by 奔跑宝BPB on 2017/6/8.
//  Copyright © 2017年 benpaobao_mac. All rights reserved.
//

/**
 glBindRenderbuffer (GLenum target, GLuint renderbuffer) 
 glFramebufferRenderbuffer (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer)
 - (BOOL)renderbufferStorage:(NSUInteger)target fromDrawable:(id<EAGLDrawable>)drawable;
 
 我们尝试观察上面两个函数和一个方法，当然下面有很多类似的函数或方法，我们发现他们的参数都是一些C数据类型，而且大多都是不同位的 Integer（整型）。这里解释一下参数，GL 表示 OpenGL 类型。而其中我们在绑定缓冲区到渲染管线时用到的是 GLenum，表示枚举类型。而最下面一个方法属于 OC 的方法，所以说第一个类型用的是 NSUInteger，但这里也是需要传枚举类型的。如何分辨？我们只需看到参数名为 target，这个和 C 函数中的参数表示是一致的
 */

#import "OpenGLESView.h"

#import "OpenGLESShaderUtils.h"

// 一个用于跟踪所有顶点信息的结构Vertex。（目前只包含位置和颜色。）
typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

// 定义了以上面这个 Vertex 结构为类型的array。
const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};

// 一个用于表示三角形顶点的数组。
const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface OpenGLESView ()

/** 创建 CAEAGLLayer */
- (void)setupEaglLayer;
/** 创建 EAGLContext */
- (void)setupEaglContext;
/** 创建 RenderBuffer（此处是 color buffer） */
- (void)setupRenderBuffer;
/** 创建 FrameBufferRenderBuffer */
- (void)setupFrameBuffer;
/** 当 UIView 的布局发生改变，由于 layer 的宽高变化，导致原有的 renderBuffer 不再相符，我们需要调用该方法销毁已经生成的 renderBuffer 和 frameBuffer */
- (void)deleteRenderBufferOrFrameBuffer;

@end

@implementation OpenGLESView

+ (Class)layerClass {
    // 只有 [CAEAGLLayer class] 类型的 layer 才支持在其上描绘 OpenGL 内容。(动态修改返回类的类型)
    return [CAEAGLLayer class];
}

- (void)setupEaglLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    // CALayer 默认是透明的，必须将不透明度设置为 YES，保证他不透明才可见
    _eaglLayer.opaque = YES;
    // 设置绘图属性
    _eaglLayer.drawableProperties = @{
                                      // kEAGLDrawablePropertyRetainedBacking : NO (告诉CoreAnimation不要试图保留任何以前绘制的图像留作以后重用。下次重现时，必须要求应用程序完全重绘一次。如果设置为 YES，那么性能和系统资源影响都较大，所以只有当 renderBuffer 需要保持其内容不变时，我们才设置为 YES)
                                      kEAGLDrawablePropertyRetainedBacking : [NSNumber numberWithBool:NO],
                                      // kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8 (告诉 CoreAnimation 用 8 位来保存 RGBA 的值，red、green、blue、alpha 共 8 位)
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                      };
}

- (void)setupEaglContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _eaglContext = [[EAGLContext alloc] initWithAPI:api];
    
    if (!_eaglContext) { // 上下文初始化失败
        NSLog(@"上下文初始化失败！");
//        exit(1); // 执行程序异常退出，直接崩
    }
    
    if (![EAGLContext setCurrentContext:_eaglContext]) { // 设置 _eaglContext 为当前上下文，并判断设置当前上下文是否成功
        _eaglContext = nil; // 清空初始化好的上下文
        NSLog(@"设置为当前上下文失败！");
//        exit(1); // 执行程序异常退出，直接崩
    }
    
    NSLog(@"设置上下文成功！");
}

- (void)setupRenderBuffer {
    // 为 renderBuffer（渲染缓存）申请 id（名字），创建渲染缓冲区域，最后赋给 _colorRenderBuffer
    // glGenRenderbuffers(<#GLsizei n#> - 申请 renderBuffer 的个数, <#GLuint *renderbuffers#> - 分配给 renderBuffer 的 id)
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 绑定渲染缓冲区到渲染管线，在后面引用 GL_RENDERBUFFER 的地方，其实就是引用 _colorRenderBuffer
    // glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // 将 renderBuffer（渲染缓存）绑定到 eaglLayer（渲染图层上），并为其分配一个共享缓存
    // renderbufferStorage:<#(NSUInteger)#> - 为哪个 renderBuffer 分配空间 fromDrawable:<#(id<EAGLDrawable>)#> - 绑定在哪个渲染图层
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer {
    // 创建帧缓冲区域
    glGenFramebuffers(1, &_frameBuffer);
    // 绑定帧缓冲区到渲染管线
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将上面我们创建出来的 renderBuffer（三大 buffer 之一）连接到 frameBuffer 上（参数二 GLenum attachment 可选填 GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT, GL_STENCIL_ATTACHMENT 中的一个，分别对应 color，depth 和 stencil 三大 buffer。）
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)deleteRenderBufferOrFrameBuffer {
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteBuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
}

/**
    2 调用glVertexAttribPointer来为vertex shader的两个输入参数配置两个合适的值。
      第二段这里，是一个很重要的方法，让我们来认真地看看它是如何工作的：
      第一个参数，声明这个属性的名称，之前我们称之为glGetAttribLocation
      第二个参数，定义这个属性由多少个值组成。譬如说 position 是由3个float（x,y,z）组成，而颜色是4个float（r,g,b,a）
      第三个，声明每一个值是什么类型。（这例子中无论是位置还是颜色，我们都用了GL_FLOAT）
      第四个，嗯……它总是false就好了。
      第五个，指 stride 的大小。这是一个种描述每个 vertex数据大小的方式。所以我们可以简单地传入 sizeof（Vertex），让编译器计算出来就好。
      最后一个，是这个数据结构的偏移量。表示在这个结构中，从哪里开始获取我们的值。Position的值在前面，所以传0进去就可以了。而颜色是紧接着位置的数据，而position的大小是3个float的大小，所以是从 3 * sizeof(float) 开始的。
 
    3 调用glDrawElements ，它最后会在每个vertex上调用我们的vertex shader，以及每个像素调用fragment shader，最终画出我们的矩形。
      它也是一个重要的方法，我们来仔细研究一下：
      第一个参数，声明用哪种特性来渲染图形。有GL_LINE_STRIP 和 GL_TRIANGLE_FAN。然而GL_TRIANGLE是最常用的，特别是与VBO 关联的时候。
      第二个，告诉渲染器有多少个图形要渲染。我们用到C的代码来计算出有多少个。这里是通过个 array的byte大小除以一个Indice类型的大小得到的。
      第三个，指每个indices中的index类型
      最后一个，在官方文档中说，它是一个指向index的指针。但在这里，我们用的是VBO，所以通过index的array就可以访问到了（在GL_ELEMENT_ARRAY_BUFFER传过了），所以这里不需要.
 */
- (void)draw {
    // 设置清屏颜色
    glClearColor(0, 1, 1, 1);
    // 用清屏颜色清楚哪个 buffer
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 表示渲染部分将在屏幕上的哪个区域呈现出来
    glViewport(self.frame.size.width * 0.25, self.frame.size.height * 0.25, self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
    
    // 将指定的 renderBuffer 绘制到屏幕上
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

/**
    创建着色器程序
 　　1 用来调用你刚刚写的动态编译方法，分别编译了 vertex shader 和 fragment shader
 　　2 调用了 glCreateProgram glAttachShader glLinkProgram 连接 vertex shader 和 fragment shader 成一个完整的program。
 　　3 调用 glGetProgramiv  lglGetProgramInfoLog 来检查是否有error，并输出信息。
 　　4 调用 glUseProgram  让OpenGL真正执行你的program
 　　5 最后，调用 glGetAttribLocation 来获取指向 vertex shader 传入变量的指针（另外一种解释：通过调用 glGetAttribLocation 我们获取到 shader 中定义的变量 vPosition 在 program 的槽位，通过该槽位我们就可以对 vPosition 进行操作。）。以后就可以通过这写指针来使用了。还有调用 glEnableVertexAttribArray 来启用这些数据。（因为默认是 disabled 的。）
 */
- (void)setupShaderProgram {
    // 1
    GLuint vertexShader = [OpenGLESShaderUtils createShaderType:GL_VERTEX_SHADER withFileName:@"VertexShader"];
    GLuint fragmentShader = [OpenGLESShaderUtils createShaderType:GL_FRAGMENT_SHADER withFileName:@"FragmentShader"];
    
    // 2
    GLuint programHandle = glCreateProgram(); // 创建着色器程序
    glAttachShader(programHandle, vertexShader); // 绑定 顶点着色器 到 着色器程序 上
    glAttachShader(programHandle, fragmentShader); // 绑定 片段着色器 到 着色器程序 上
    glLinkProgram(programHandle); // 连接着色器程序
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return;
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot); 
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setupEaglContext];
    
    [self deleteRenderBufferOrFrameBuffer];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    // 创建着色器程序
    [self setupShaderProgram];
    
    [self draw];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupEaglLayer];
//        [self setupEaglContext];
    }
    return self;
}

@end
