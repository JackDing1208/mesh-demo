//
//  RCTMesh.m
//  application
//
//  Created by MXCHIP on 2019/12/23.
//  Copyright © 2012-2019 MXCHIP - Smart Plus Team. All rights reserved.
//

#import "RCTBLEMesh.h"
#import "application-Swift.h"


@implementation RCTBLEMesh
{
  
}
  
RCT_EXPORT_MODULE();
- (NSArray<NSString *> *)supportedEvents
{
  return @[
           @"mesh",
           @"mesh_on_scan",
           @"mesh_on_connect",
           @"mesh_on_disconnect"
           ];
}
  
// 加载应用页面
// MARK: ⌘
// MARK: setup()
RCT_EXPORT_METHOD(setup)
{
  [[MeshSDK getSharedInstance] setup];
}
  
RCT_EXPORT_METHOD(getAllNetworkKeys)
{
  NSArray *allNetworkKeys = [[MeshSDK getSharedInstance] getAllNetworkKeys];
  NSLog(@"allNetworkKeys: %@", allNetworkKeys);
}
  
// 检查权限
// MARK: ⌘
// MARK: checkPermission(callback)
RCT_EXPORT_METHOD(checkPermission:(RCTResponseSenderBlock)callback)
{
  [[MeshSDK getSharedInstance] checkPermissionWithCallback:^(NSString * permission, BOOL success) {
    callback(@[permission]);
  }];
}



@end
