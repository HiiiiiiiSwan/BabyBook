import uuid
import os

PROJECT_DIR = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/BabyBook"

def gen_uuid():
    return uuid.uuid4().hex.upper()[:24]

# 收集所有 Swift 文件
swift_files = []
for root, dirs, files in os.walk(os.path.join(PROJECT_DIR, "Sources/BabyBookApp")):
    for f in files:
        if f.endswith(".swift"):
            swift_files.append(os.path.join(root, f))
swift_files.sort()

# 收集资源目录（只包含目录，不包含单个文件）
resource_dirs = []
resources_base = os.path.join(PROJECT_DIR, "Sources/BabyBookApp/Resources")
for d in os.listdir(resources_base):
    full_path = os.path.join(resources_base, d)
    if os.path.isdir(full_path):
        resource_dirs.append(full_path)

# 单独处理 xcassets
xcassets_path = os.path.join(resources_base, "Assets.xcassets")
has_xcassets = os.path.exists(xcassets_path)

print(f"找到 {len(swift_files)} 个 Swift 文件")
print(f"找到 {len(resource_dirs)} 个资源目录")

# 生成 UUID
target_uuid = gen_uuid()
project_uuid = gen_uuid()
main_group_uuid = gen_uuid()
products_group_uuid = gen_uuid()
product_ref_uuid = gen_uuid()

# 文件引用和构建文件
file_refs = {}
build_files = {}
resource_build_files = {}

for f in swift_files:
    rel = f[len(PROJECT_DIR)+1:]
    u = gen_uuid()
    file_refs[rel] = u
    build_files[rel] = gen_uuid()

# 资源目录引用（使用 folder reference）
resource_dir_refs = {}
for d in resource_dirs:
    rel = d[len(PROJECT_DIR)+1:]
    name = os.path.basename(d)
    u = gen_uuid()
    resource_dir_refs[rel] = u
    resource_build_files[rel] = gen_uuid()

# xcassets 引用
xcassets_ref = None
xcassets_build = None
if has_xcassets:
    xcassets_rel = "Sources/BabyBookApp/Resources/Assets.xcassets"
    xcassets_ref = gen_uuid()
    xcassets_build = gen_uuid()

# 目录组
all_dirs = set()
for f in swift_files:
    d = os.path.dirname(f)
    while d.startswith(PROJECT_DIR + "/Sources"):
        all_dirs.add(d)
        d = os.path.dirname(d)

# 添加资源目录到组
for d in resource_dirs:
    parent = os.path.dirname(d)
    while parent.startswith(PROJECT_DIR + "/Sources"):
        all_dirs.add(parent)
        parent = os.path.dirname(parent)
    all_dirs.add(d)

group_uuids = {}
for d in sorted(all_dirs):
    group_uuids[d] = gen_uuid()

# 构建 PBXFileReference 部分
file_ref_section = ""
for rel, u in file_refs.items():
    name = os.path.basename(rel)
    # 使用相对于父目录的路径
    rel_to_sources = rel  # 保持相对路径
    if rel.endswith(".swift"):
        file_ref_section += f"\t\t{u} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = \"{name}\"; path = \"{name}\"; sourceTree = \"<group>\"; }};\n"

# 资源目录引用（folder reference）
for rel, u in resource_dir_refs.items():
    name = os.path.basename(rel)
    file_ref_section += f"\t\t{u} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder; name = \"{name}\"; path = \"{name}\"; sourceTree = \"<group>\"; }};\n"

# xcassets 引用
if xcassets_ref:
    file_ref_section += f"\t\t{xcassets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = \"Assets.xcassets\"; path = \"Assets.xcassets\"; sourceTree = \"<group>\"; }};\n"

# 构建 PBXBuildFile 部分
build_file_section = ""
for rel, u in build_files.items():
    name = os.path.basename(rel)
    build_file_section += f"\t\t{u} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */; }};\n"

for rel, u in resource_build_files.items():
    name = os.path.basename(rel)
    build_file_section += f"\t\t{u} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {resource_dir_refs[rel]} /* {name} */; }};\n"

if xcassets_build:
    build_file_section += f"\t\t{xcassets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {xcassets_ref} /* Assets.xcassets */; }};\n"

# 构建 PBXGroup 部分
group_section = ""
for d in sorted(all_dirs):
    u = group_uuids[d]
    rel_d = d[len(PROJECT_DIR)+1:]
    name = os.path.basename(d) if d != PROJECT_DIR else "BabyBook"

    children = []
    # 子目录
    for sub in sorted(all_dirs):
        if os.path.dirname(sub) == d:
            children.append(f"{group_uuids[sub]} /* {os.path.basename(sub)} */")
    # Swift 文件
    for f in swift_files:
        if os.path.dirname(f) == d:
            rel_f = f[len(PROJECT_DIR)+1:]
            children.append(f"{file_refs[rel_f]} /* {os.path.basename(rel_f)} */")
    # 资源目录（只在 Resources 目录下添加）
    if d == os.path.join(PROJECT_DIR, "Sources/BabyBookApp/Resources"):
        for rel_dir, uu in resource_dir_refs.items():
            children.append(f"{uu} /* {os.path.basename(rel_dir)} */")
        if xcassets_ref:
            children.append(f"{xcassets_ref} /* Assets.xcassets */")

    children_str = "\n".join([f"\t\t\t\t{c}," for c in children])
    # 移除可能的双逗号
    children_str = children_str.replace(",,\n", ",\n")

    if d == os.path.join(PROJECT_DIR, "Sources"):
        group_section += f"""\t\t{u} /* Sources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t);
\t\t\tpath = Sources;
\t\t\tsourceTree = "<group>";
\t\t}};
"""
    else:
        group_section += f"""\t\t{u} /* {name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t);
\t\t\tpath = {name};
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# 构建资源构建列表
resource_build_list = ""
for rel, u in resource_build_files.items():
    name = os.path.basename(rel)
    resource_build_list += f"\t\t\t\t{u} /* {name} in Resources */,\n"
if xcassets_build:
    resource_build_list += f"\t\t\t\t{xcassets_build} /* Assets.xcassets in Resources */,\n"

# 构建源码构建列表
source_build_list = ""
for rel, u in build_files.items():
    name = os.path.basename(rel)
    source_build_list += f"\t\t\t\t{u} /* {name} in Sources */,\n"

# 生成 UUID
frameworks_phase_uuid = gen_uuid()
sources_phase_uuid = gen_uuid()
resources_phase_uuid = gen_uuid()
debug_config_uuid = gen_uuid()
release_config_uuid = gen_uuid()
debug_project_config_uuid = gen_uuid()
release_project_config_uuid = gen_uuid()
build_config_list_target_uuid = gen_uuid()
build_config_list_project_uuid = gen_uuid()

# 找到 Sources 目录的 UUID
sources_dir_uuid = group_uuids.get(os.path.join(PROJECT_DIR, "Sources"), gen_uuid())

# 生成 pbxproj 内容
pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_file_section}/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{product_ref_uuid} /* BabyBookApp.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BabyBookApp.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_ref_section}/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_uuid} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_dir_uuid} /* Sources */,
\t\t\t\t{products_group_uuid} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_uuid} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_ref_uuid} /* BabyBookApp.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
{group_section}/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_uuid} /* BabyBookApp */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list_target_uuid} /* Build configuration list for PBXNativeTarget "BabyBookApp" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_uuid} /* Sources */,
\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,
\t\t\t\t{resources_phase_uuid} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = BabyBookApp;
\t\t\tproductName = BabyBookApp;
\t\t\tproductReference = {product_ref_uuid} /* BabyBookApp.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_uuid} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tbuildConfigurationList = {build_config_list_project_uuid} /* Build configuration list for PBXProject "BabyBook" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_uuid};
\t\t\tproductRefGroup = {products_group_uuid} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_uuid} /* BabyBookApp */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_uuid} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{resource_build_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_uuid} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{source_build_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_config_uuid} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = 7BSKXTD6DF;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = "";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.shihui.babybook;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\t// 隐私权限描述
\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "需要访问相机以拍摄宝宝照片，用于生成专属绘本";
\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "需要访问相册以选择宝宝照片，用于生成专属绘本";
\t\t\t\t// 加密声明：使用标准 HTTPS 和系统 Keychain，属于豁免范围
\t\t\t\tINFOPLIST_KEY_ITSEncryptionExportComplianceCode = "";  // 空值表示使用标准加密，无需文档
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_uuid} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = 7BSKXTD6DF;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = "";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.shihui.babybook;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\t// 隐私权限描述
\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "需要访问相机以拍摄宝宝照片，用于生成专属绘本";
\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "需要访问相册以选择宝宝照片，用于生成专属绘本";
\t\t\t\t// 加密声明：使用标准 HTTPS 和系统 Keychain，属于豁免范围
\t\t\t\tINFOPLIST_KEY_ITSEncryptionExportComplianceCode = "";  // 空值表示使用标准加密，无需文档
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_project_config_uuid} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_project_config_uuid} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_target_uuid} /* Build configuration list for PBXNativeTarget "BabyBookApp" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_uuid} /* Debug */,
\t\t\t\t{release_config_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{build_config_list_project_uuid} /* Build configuration list for PBXProject "BabyBook" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_project_config_uuid} /* Debug */,
\t\t\t\t{release_project_config_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {project_uuid} /* Project object */;
}}
"""

# 写入文件
with open(os.path.join(PROJECT_DIR, "BabyBook.xcodeproj", "project.pbxproj"), "w") as f:
    f.write(pbxproj)

print(f"✅ 已生成 Xcode 项目，包含 {len(swift_files)} 个 Swift 文件和 {len(resource_dirs)} 个资源目录")
print("✅ 已添加 NSCameraUsageDescription 和 NSPhotoLibraryUsageDescription 隐私权限描述")
print("✅ 已添加 ITSEncryptionExportComplianceCode 加密合规声明")
