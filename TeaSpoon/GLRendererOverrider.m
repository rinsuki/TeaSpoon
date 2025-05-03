//
//  GLRendererOverrider.m
//  TeaSpoon
//
//  Created by user on 2021/07/20.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>
#import "TeaSpoon-Swift.h"
#import "GLRendererOverrider.h"

static const char* getGlRendererString() {
    return "Adreno (TM) 650";
}

#define PAGESIZE (16*1024)

void teaspoonOverrideGLRendererString() {
    static BOOL passed = false;
    if (passed) return;
    passed = true;
    if (![NativeFunctionOverrideHelper.shared checkShouldOverrideOpenGLRendererString]) {
        return;
    }

    int libOpenglRenderIndex = [NativeFunctionOverrideHelper.shared isLibraryIsLoadedWithSuffix:@"/libgfxstream_backend.dylib"];
    if (libOpenglRenderIndex <= 0) {
        return;
    }
    // find address of original getGlRendererString
    // original function: const char* GLEScontext::getRenderString(bool isGles1);
    // source: https://android.googlesource.com/platform/external/qemu/+/e106d9eeab3c96db145bc5b59188283acdba3df8/android/android-emugl/host/libs/Translator/GLcommon/GLEScontext.cpp#1682
    void* origFuncPtr = (void*)[NativeFunctionOverrideHelper.shared
                                addressWithImageIndex: libOpenglRenderIndex
                                symbolName: @"__ZNK11GLEScontext17getRendererStringEb"];
    if (origFuncPtr == NULL) {
        return;
    }
    printf("[TeaSpoon] original getGlRendererString = %p\n", origFuncPtr);
    printf("[TeaSpoon] replacing to TeaSpoon implementation (at %p)...\n", getGlRendererString);
    void* origPageStart = (void*) (((pointer_t)origFuncPtr) & ~(PAGESIZE - 1));
    printf("[TeaSpoon] pagestart = %p\n", origPageStart);
#if defined __x86_64__
    if (mprotect(origPageStart, (origFuncPtr + 12) - origPageStart, PROT_READ | PROT_WRITE | PROT_EXEC) != 0) {
        printf("[TeaSpoon] mprotect RWX fail: %d\n", errno);
        return;
    };
    uint8_t* func = origFuncPtr;
    // movabs %rax, getGlRendererString
    func[0] = 0x48;
    func[1] = 0xB8;
    *((uint64_t*)(uint8_t*)(func + 2)) = (uint64_t)getGlRendererString;
    // jmp %rax
    func[10] = 0xFF;
    func[11] = 0xE0;
    printf("[TeaSpoon] finish self modifiying, recovery R-X...\n");
    if (mprotect(origPageStart, (origFuncPtr + 12) - origPageStart, PROT_READ | PROT_EXEC) != 0) {
        printf("[TeaSpoon] mprotect R-X fail: %d\n", errno);
        return;
    };
    printf("[TeaSpoon] patch to getGlRendererString is finished!\n");
#elif defined __arm64__
    if (mprotect(origPageStart, (origFuncPtr + 16) - origPageStart, PROT_READ | PROT_WRITE) != 0) {
        printf("[TeaSpoon] mprotect RW fail: %d\n", errno);
        return;
    };
    uint8_t* func = origFuncPtr;
    // ldr x0, .+8
    func[0] = 0x40;
    func[1] = 0x00;
    func[2] = 0x00;
    func[3] = 0x58;
    // br x0
    func[4] = 0x00;
    func[5] = 0x00;
    func[6] = 0x1F;
    func[7] = 0xD6;
    // address (will load by ldr)
    *((uint64_t*)(uint8_t*)(func + 8)) = (uint64_t)getGlRendererString;
    // write address
    printf("[TeaSpoon] finish self modifiying, recovery R-X...\n");
    if (mprotect(origPageStart, (origFuncPtr + 16) - origPageStart, PROT_READ | PROT_EXEC) != 0) {
        printf("[TeaSpoon] mprotect R-X fail: %d\n", errno);
        return;
    };
    printf("[TeaSpoon] arm64 patch to getGlRendererString is finished!\n");
#else
#error "Unsupported architecture"
#endif
}
