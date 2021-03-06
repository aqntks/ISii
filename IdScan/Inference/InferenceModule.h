
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InferenceModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable NSArray<NSNumber*>*)detectImage:(void*)imageBuffer NS_SWIFT_NAME(detect(image:));
- (nullable NSArray<NSNumber*>*)detectImageHangul:(void*)imageBuffer NS_SWIFT_NAME(detectHangul(image:));

@end

NS_ASSUME_NONNULL_END
