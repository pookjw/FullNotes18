#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <substrate.h>
#include <vector>
#include <dlfcn.h>

namespace AE_os_feature_enabled_impl {
    BOOL (*original)(const char *arg0, const char *arg1);
    BOOL custom(const char *arg0, const char *arg1) {
        if (!std::strcmp(arg0, "CoreHandwriting") && !std::strcmp(arg1, "synthesis")) {
            return YES;
        } else if (!std::strcmp(arg0, "CoreHandwriting") && !std::strcmp(arg1, "magic_paper_math")) {
            return YES;
        } else if (!std::strcmp(arg0, "PencilAndPaper") && !std::strcmp(arg1, "MathPaper")) {
            return YES;
        } else if (!std::strcmp(arg0, "PencilAndPaper") && !std::strcmp(arg1, "AutoRefine")) {
            return YES;
        } else {
            return original(arg0, arg1);
        }
    }
}

namespace fullnotes18 {
    BOOL customGetter(id self, SEL _cmd) { return YES; }
    void (*originalSetter)(id self, SEL _cmd, BOOL flag);
    void customSetter(id self, SEL _cmd, BOOL flag) { originalSetter(self, _cmd, YES); }

    namespace _PKAutoRefineController {
        namespace setIsAutoRefineOn_force_ {
            void (*original)(id self, SEL _cmd, BOOL on, BOOL force);
            void custom(id self, SEL _cmd, BOOL on, BOOL force) {
                original(self, _cmd, YES, YES);
            }
        }
    }

    namespace __PKCurrentDeviceSupportsAutoRefine {
        BOOL custom(void) { return YES; }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    const std::vector<SEL> sels {
        sel_registerName("appShortcutsEnabled"),
        sel_registerName("realtimeCollaborationEnabled"),
        sel_registerName("pagesHandoffEnabled"),
        sel_registerName("lockedNotesV1NeoEnabled"),
        sel_registerName("blockQuoteEnabled"),
        sel_registerName("imapSyncEnabled"),
        sel_registerName("audioTranscriptionEnabled"),
        sel_registerName("callRecordingEnabled"),
        sel_registerName("transcriptionEvaluationEnabled"),
        sel_registerName("mathEnabled"),
        sel_registerName("graphingEnabled"),
        sel_registerName("scrubbingEnabled"),
        sel_registerName("greyParrotEnabled"),
        sel_registerName("greyParrotUniversalAppEnabled"),
        sel_registerName("emphasisEnabled"),
        sel_registerName("inlineFormFillingEnabled"),
        sel_registerName("siriSMART"),
        sel_registerName("uniquelyiPadFluidTransitionsEnabled"),
        sel_registerName("generationTool"),
        sel_registerName("offlineCallTranscriptionEnabled")
    };
        
    for (SEL cmd : sels) {
        Method method = class_getClassMethod(NSClassFromString(@"_TtC11MobileNotes14ICFeatureFlags"), cmd);
        method_setImplementation(method, reinterpret_cast<IMP>(fullnotes18::customGetter));
    }

    {
        void *handle = dlopen("/usr/lib/system/libsystem_featureflags.dylib", RTLD_NOW);
        void *symbol = dlsym(handle, "_os_feature_enabled_impl");
        MSHookFunction(symbol, reinterpret_cast<void *>(&AE_os_feature_enabled_impl::custom), reinterpret_cast<void **>(&AE_os_feature_enabled_impl::original));
    }

    MSHookMessageEx(
        NSClassFromString(@"PKRecognitionController"),
        sel_registerName("currentDeviceSupportsAutoRefine"),
        reinterpret_cast<IMP>(&fullnotes18::customGetter),
        nullptr
    );

    {
        Method method = class_getClassMethod(NSClassFromString(@"PKSettingsDaemon"), sel_registerName("autoRefineEnabled"));
        method_setImplementation(method, reinterpret_cast<IMP>(fullnotes18::customGetter));
    }

    {
        Method method = class_getClassMethod(NSClassFromString(@"PKRecognitionSessionManager"), sel_registerName("hasAutoRefineLocaleEnabled"));
        method_setImplementation(method, reinterpret_cast<IMP>(fullnotes18::customGetter));
    }

    MSHookMessageEx(
        NSClassFromString(@"PKTiledView"),
        sel_registerName("isAutoRefineEnabled"),
        reinterpret_cast<IMP>(&fullnotes18::customGetter),
        nullptr
    );

    MSHookMessageEx(
        NSClassFromString(@"PKTiledView"),
        sel_registerName("setIsAutoRefineEnabled:"),
        reinterpret_cast<IMP>(&fullnotes18::customSetter),
        reinterpret_cast<IMP *>(&fullnotes18::originalSetter)
    );

    MSHookMessageEx(
        NSClassFromString(@"PKAutoRefineController"),
        sel_registerName("setIsAutoRefineOn:force:"),
        reinterpret_cast<IMP>(&fullnotes18::_PKAutoRefineController::setIsAutoRefineOn_force_::custom),
        reinterpret_cast<IMP *>(&fullnotes18::_PKAutoRefineController::setIsAutoRefineOn_force_::original)
    );

    MSImageRef PencilKit = MSGetImageByName("/System/Library/Frameworks/PencilKit.framework/PencilKit");
    void *_PKCurrentDeviceSupportsAutoRefine = MSFindSymbol(PencilKit, "_PKCurrentDeviceSupportsAutoRefine");
    MSHookFunction(
        _PKCurrentDeviceSupportsAutoRefine,
        reinterpret_cast<void *>(&fullnotes18::__PKCurrentDeviceSupportsAutoRefine::custom),
        nullptr
    );

    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.UIKit"];
    [userDefaults setBool:YES forKey:@"UIAutoRefineEnabledKey"];
    [userDefaults synchronize];
    [userDefaults release];

    [pool release];
}
