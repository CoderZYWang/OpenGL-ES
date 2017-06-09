//
//  OpenGLESShaderUtils.h
//  OpenGLES_Demo_01
//
//  Created by 奔跑宝BPB on 2017/6/9.
//  Copyright © 2017年 benpaobao_mac. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OpenGLES/ES2/gl.h>

@interface OpenGLESShaderUtils : NSObject

/**
    动态创建并返回编译成功的一个 顶点着色器/片段着色器
    传入 shader 的 文件名 和 文件类型（一般是.glsl）

    1.编辑着色器代码
    2.创建着色器 
    3.编译着色器
 */
+ (GLuint)createShaderType:(GLenum)shaderType withFileName:(NSString *)fileName;

@end
