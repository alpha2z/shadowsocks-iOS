//
// Created by clowwindy on 14-2-27.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "ShadowsocksRunner.h"
#import "local.h"


@implementation ShadowsocksRunner {

}

+ (BOOL)settingsAreNotComplete {
    if ((![ShadowsocksRunner isUsingPublicServer]) && ([[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksIPKey] == nil ||
            [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPortKey] == nil ||
            [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPasswordKey] == nil)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)runProxy {
    if (![ShadowsocksRunner settingsAreNotComplete]) {
        local_main();
        return YES;
    } else {
#ifdef DEBUG
        NSLog(@"warning: settings are not complete");
#endif
        return NO;
    }
}

+ (void)reloadConfig {
    if (![ShadowsocksRunner settingsAreNotComplete]) {
        if ([ShadowsocksRunner isUsingPublicServer]) {
            set_config("106.186.124.182", "8910", "Shadowsocks", "aes-128-cfb");
            memcpy(shadowsocks_key, "\x45\xd1\xd9\x9e\xbd\xf5\x8c\x85\x34\x55\xdd\x65\x46\xcd\x06\xd3", 16);
        } else {
            NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksEncryptionKey];
            if (!v) {
                v = @"aes-256-cfb";
            }
            set_config([[[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksIPKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPortKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPasswordKey] cStringUsingEncoding:NSUTF8StringEncoding], [v cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
}

+ (void)openSSURL:(NSURL *)url {
    if (!url.host) {
        return;
    }
    NSString *urlString = [url absoluteString];
    int i = 0;
    NSString *errorReason = nil;
    while(i < 2) {
        if (i == 1) {
            NSData *data = [[NSData alloc] initWithBase64Encoding:url.host];
            NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            urlString = decodedString;
        }
        i++;
        urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
        NSRange firstColonRange = [urlString rangeOfString:@":"];
        NSRange lastColonRange = [urlString rangeOfString:@":" options:NSBackwardsSearch];
        NSRange lastAtRange = [urlString rangeOfString:@"@" options:NSBackwardsSearch];
        if (firstColonRange.length == 0) {
            errorReason = @"colon not found";
            continue;
        }
        if (firstColonRange.location == lastColonRange.location) {
            errorReason = @"only one colon";
            continue;
        }
        if (lastAtRange.length == 0) {
            errorReason = @"at not found";
            continue;
        }
        if (!((firstColonRange.location < lastAtRange.location) && (lastAtRange.location < lastColonRange.location))) {
            errorReason = @"wrong position";
            continue;
        }
        NSString *method = [urlString substringWithRange:NSMakeRange(0, firstColonRange.location)];
        NSString *password = [urlString substringWithRange:NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
        NSString *IP = [urlString substringWithRange:NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
        NSString *port = [urlString substringWithRange:NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:IP];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:port];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:password];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksEncryptionKey value:method];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShadowsocksUsePublicServer];
        [ShadowsocksRunner reloadConfig];
        return;
    }

    NSLog(@"%@", errorReason);
}

+ (void)saveConfigForKey:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}


+ (void)setUsingPublicServer:(BOOL)use {
    [[NSUserDefaults standardUserDefaults] setBool:use forKey:kShadowsocksUsePublicServer];

}

+ (BOOL)isUsingPublicServer {
    NSNumber *usePublicServer = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksUsePublicServer];
    if (usePublicServer != nil) {
        return [usePublicServer boolValue];
    } else {
        return YES;
    }
}

@end
