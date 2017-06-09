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

- (void)draw {
    // 设置清屏颜色
    glClearColor(0, 1, 1, 1);
    // 用清屏颜色清楚哪个 buffer
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 将指定的 renderBuffer 绘制到屏幕上
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setupEaglContext];
    
    [self deleteRenderBufferOrFrameBuffer];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
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
