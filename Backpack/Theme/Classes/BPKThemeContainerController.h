/*
 * Backpack - Skyscanner's Design System
 *
 * Copyright 2019 Skyscanner Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ThemeContainerController) @interface BPKThemeContainerController : UIViewController

- (instancetype)initWithThemeContainer:(UIView *)container rootViewController:(UIViewController *)rootViewController;

@property(nonatomic, assign, getter=isThemeActive) BOOL themeActive;
@property(nonatomic,  strong) UIView *themeContainer;
@end

NS_ASSUME_NONNULL_END