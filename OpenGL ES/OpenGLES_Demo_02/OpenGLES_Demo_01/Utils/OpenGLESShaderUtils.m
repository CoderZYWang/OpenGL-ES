//
//  OpenGLESShaderUtils.m
//  OpenGLES_Demo_01
//
//  Created by 奔跑宝BPB on 2017/6/9.
//  Copyright © 2017年 benpaobao_mac. All rights reserved.
//

/**
    1 将 .glsl 文件加载并转化为字符串用于接下来的操作。
    2 调用 glCreateShader 来创建一个代表 shader 的 OpenGL 对象。这时你必须告诉 OpenGL，你想创建 fragment shader 还是 vertex shader。所以便有了这个参数：shaderType
    3 调用glShaderSource ，让OpenGL获取到这个shader的源代码。（就是我们写的那个）这里我们还把 NSString 转换成 C-string
    4 最后，调用glCompileShader 在运行时编译 shader
    5 如果编译失败，glGetShaderiv 和 glGetShaderInfoLog 会把 error 信息输出到屏幕。（然后退出）
 */

#import "OpenGLESShaderUtils.h"

@implementation OpenGLESShaderUtils

+ (GLuint)createShaderType:(GLenum)shaderType withFileName:(NSString *)fileName {
    // 1
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        // 打印错误信息的本地化描述
        NSLog(@"读取 shader 路径有误：%@", error.localizedDescription);
        return 0;
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess; // 是否编译成功
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess); // 获取完成状态
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"着色器编译失败 - %@", messageString);
        return 0;
    }
    
    return shaderHandle;
}

@end
