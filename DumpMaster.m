#import "DumpMaster.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation DumpMaster

+ (instancetype)sharedInstance {
    static DumpMaster *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DumpMaster alloc] init];
    });
    return instance;
}

- (void)startDump {
    NSLog(@"🔍 Starting runtime class dump...");
    
    NSMutableDictionary *allData = [NSMutableDictionary dictionary];
    NSMutableArray *allClasses = [NSMutableArray array];
    
    // 1. الحصول على جميع الكلاسات المسجلة
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            Class cls = classes[i];
            NSString *className = NSStringFromClass(cls);
            
            // تخطي الكلاسات النظامية (اختياري)
            if ([className hasPrefix:@"NS"] || [className hasPrefix:@"__"] || 
                [className hasPrefix:@"OS_"] || [className hasPrefix:@"_"] ||
                [className containsString:@"GS"]) {
                continue;
            }
            
            NSMutableDictionary *classInfo = [NSMutableDictionary dictionary];
            classInfo[@"name"] = className;
            classInfo[@"superclass"] = NSStringFromClass(class_getSuperclass(cls)) ?: @"nil";
            
            // 2. استخراج الأساليب (Methods)
            NSMutableArray *methods = [NSMutableArray array];
            unsigned int methodCount = 0;
            Method *methodList = class_copyMethodList(cls, &methodCount);
            
            for (unsigned int j = 0; j < methodCount; j++) {
                Method method = methodList[j];
                SEL selector = method_getName(method);
                NSString *methodName = NSStringFromSelector(selector);
                [methods addObject:methodName];
            }
            free(methodList);
            classInfo[@"methods"] = methods;
            
            // 3. استخراج الخصائص (Properties)
            NSMutableArray *properties = [NSMutableArray array];
            unsigned int propCount = 0;
            objc_property_t *propList = class_copyPropertyList(cls, &propCount);
            
            for (unsigned int j = 0; j < propCount; j++) {
                objc_property_t prop = propList[j];
                NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
                [properties addObject:propName];
            }
            free(propList);
            classInfo[@"properties"] = properties;
            
            // 4. استخراج البروتوكولات (Protocols)
            NSMutableArray *protocols = [NSMutableArray array];
            unsigned int protocolCount = 0;
            Protocol * __unsafe_unretained *protocolList = class_copyProtocolList(cls, &protocolCount);
            
            for (unsigned int j = 0; j < protocolCount; j++) {
                Protocol *proto = protocolList[j];
                NSString *protoName = [NSString stringWithUTF8String:protocol_getName(proto)];
                [protocols addObject:protoName];
            }
            free(protocolList);
            classInfo[@"protocols"] = protocols;
            
            // 5. استخراج الـ Instance Variables (Ivars)
            NSMutableArray *ivars = [NSMutableArray array];
            unsigned int ivarCount = 0;
            Ivar *ivarList = class_copyIvarList(cls, &ivarCount);
            
            for (unsigned int j = 0; j < ivarCount; j++) {
                Ivar ivar = ivarList[j];
                NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
                NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
                [ivars addObject:@{@"name": ivarName, @"type": ivarType}];
            }
            free(ivarList);
            classInfo[@"ivars"] = ivars;
            
            [allClasses addObject:classInfo];
        }
        free(classes);
    }
    
    allData[@"classes"] = allClasses;
    allData[@"total_classes"] = @(allClasses.count);
    allData[@"timestamp"] = [NSDate date];
    allData[@"app_name"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?: @"Unknown";
    allData[@"bundle_id"] = [[NSBundle mainBundle] bundleIdentifier] ?: @"Unknown";
    
    // 6. حفظ الملف
    [self saveDumpToFile:allData];
}

- (void)saveDumpToFile:(NSDictionary *)dumpData {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dumpData
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (error) {
        NSLog(@"❌ Failed to serialize JSON: %@", error);
        return;
    }
    
    // تحديد مسار الحفظ
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileName = [NSString stringWithFormat:@"dump_%@.json", @([[NSDate date] timeIntervalSince1970])];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    
    BOOL success = [jsonData writeToFile:filePath atomically:YES];
    
    if (success) {
        NSLog(@"✅ Dump saved: %@", filePath);
        [self showNotification:[NSString stringWithFormat:@"✅ Dump saved: %@", fileName]];
        [self showShareSheet:filePath];
    } else {
        NSLog(@"❌ Failed to save dump");
    }
}

- (void)showNotification:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📦 DumpMaster"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow && keyWindow.rootViewController) {
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showShareSheet:(NSString *)filePath {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow && keyWindow.rootViewController) {
            [keyWindow.rootViewController presentViewController:activityVC animated:YES completion:nil];
        }
    });
}

@end
