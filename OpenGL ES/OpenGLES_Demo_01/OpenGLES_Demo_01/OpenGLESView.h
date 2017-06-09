//
//  OpenGLESView.h
//  OpenGLES_Demo_01
//
//  Created by 奔跑宝BPB on 2017/6/8.
//  Copyright © 2017年 benpaobao_mac. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface OpenGLESView : UIView {
    /** OpenGL ES 显示 layer，必须是 CAEAGLLayer 类型 */
    CAEAGLLayer *_eaglLayer;
    
    /** OpenGL ES 渲染上下文（在iOS中对应的实现为EAGLContext），这个 context 管理所有使用OpenGL ES 进行描绘的状态，命令以及资源信息。然后，需要将它设置为当前 context，因为我们要使用 OpenGL ES 进行渲染（描绘） */
    EAGLContext *_eaglContext;
    
    /** 有了上下文，openGL还需要在一块 buffer 上进行描绘，这块 buffer 就是 RenderBuffer，此处我们用最基本的 color buffer */
    GLuint _colorRenderBuffer;
    
    /** framebuffer object 通常称为 FBO，它相当于 RenderBuffer(color, depth, stencil)的管理者，三大buffer 可以附加到一个 FBO 上。本质上时将 frameBuffer 内容渲染到屏幕时需要。 */
    GLuint _frameBuffer;
}

@end
