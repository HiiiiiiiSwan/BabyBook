#!/usr/bin/env python3
"""
BabyBook Xcode 项目生成脚本
使用 Folder References 保持资源目录结构，避免文件名冲突
"""

import os
import hashlib

PROJECT_ROOT = "/Users/wang/Documents/Vibe coding/【新】宝贝绘本/BabyBook"
SOURCES_DIR = os.path.join(PROJECT_ROOT, "Sources", "BabyBookApp")
PROJECT_NAME = "BabyBook"
BUNDLE_ID = "com.babybook.app"

def generate_uuid(seed):
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return f"{h[:8]}{h[8:12]}{h[12:16]}{h[16:20]}{h[20:24]}"

def collect_files():
    swift_files = []
    resource_files = []
    asset_catalogs = []
    folder_refs = []  # Folder References (蓝色文件夹)

    # Swift 文件
    for root, dirs, files in os.walk(SOURCES_DIR):
        rel_root = os.path.relpath(root, SOURCES_DIR)
        for f in sorted(files):
            if f.endswith(".swift"):
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, SOURCES_DIR)
                swift_files.append({
                    "path": full_path,
                    "rel_path": rel_path,
                    "name": f,
                    "dir": os.path.dirname(rel_path) if rel_path != f else ""
                })

    # 资源文件 - 只处理 Resources 根目录下的文件
    # 子目录作为 Folder References
    resources_dir = os.path.join(SOURCES_DIR, "Resources")
    if os.path.exists(resources_dir):
        for root, dirs, files in os.walk(resources_dir):
            rel_root = os.path.relpath(root, resources_dir)

            # 跳过 xcassets 内部
            if ".xcassets" in root:
                if root.endswith(".xcassets") and rel_root == "Assets.xcassets":
                    asset_catalogs.append({
                        "path": root,
                        "rel_path": os.path.relpath(root, SOURCES_DIR),
                        "name": "Assets.xcassets",
                        "dir": "Resources"
                    })
                continue

            # Resources 根目录下的文件
            if rel_root == ".":
                for f in sorted(files):
                    if not f.startswith("."):
                        full_path = os.path.join(root, f)
                        rel_path = os.path.relpath(full_path, SOURCES_DIR)
                        resource_files.append({
                            "path": full_path,
                            "rel_path": rel_path,
                            "name": f,
                            "dir": "Resources"
                        })
            else:
                # 子目录 - 作为 Folder Reference
                # 只添加一次
                dir_name = os.path.basename(rel_root)
                parent_dir = os.path.dirname(rel_root)
                if parent_dir == "":
                    # 这是 Resources 的直接子目录
                    folder_path = os.path.join(resources_dir, dir_name)
                    # 检查是否已添加
                    already_added = any(fr["name"] == dir_name for fr in folder_refs)
                    if not already_added:
                        folder_refs.append({
                            "path": folder_path,
                            "rel_path": os.path.relpath(folder_path, SOURCES_DIR),
                            "name": dir_name,
                            "dir": "Resources"
                        })

    # PrivacyInfo.xcprivacy（放在 Sources/BabyBookApp 根目录）
    privacy_info_path = os.path.join(SOURCES_DIR, "PrivacyInfo.xcprivacy")
    if os.path.exists(privacy_info_path):
        resource_files.append({
            "path": privacy_info_path,
            "rel_path": "PrivacyInfo.xcprivacy",
            "name": "PrivacyInfo.xcprivacy",
            "dir": ""
        })

    swift_files.sort(key=lambda x: x["rel_path"])
    resource_files.sort(key=lambda x: x["rel_path"])
    asset_catalogs.sort(key=lambda x: x["rel_path"])
    folder_refs.sort(key=lambda x: x["name"])

    return swift_files, resource_files, asset_catalogs, folder_refs

def generate_project():
    swift_files, resource_files, asset_catalogs, folder_refs = collect_files()

    print(f"找到 {len(swift_files)} 个 Swift 文件")
    print(f"找到 {len(resource_files)} 个根资源文件")
    print(f"找到 {len(asset_catalogs)} 个资源目录")
    print(f"找到 {len(folder_refs)} 个文件夹引用")

    xcodeproj_dir = os.path.join(PROJECT_ROOT, f"{PROJECT_NAME}.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)

    # UUIDs
    root_object_uuid = generate_uuid("rootObject")
    main_group_uuid = generate_uuid("mainGroup")
    products_group_uuid = generate_uuid("productsGroup")
    sources_build_phase_uuid = generate_uuid("sourcesBuildPhase")
    resources_build_phase_uuid = generate_uuid("resourcesBuildPhase")
    frameworks_build_phase_uuid = generate_uuid("frameworksBuildPhase")
    target_uuid = generate_uuid("nativeTarget")
    debug_config_uuid = generate_uuid("debugBuildConfig")
    release_config_uuid = generate_uuid("releaseBuildConfig")
    target_debug_config_uuid = generate_uuid("targetDebugConfig")
    target_release_config_uuid = generate_uuid("targetReleaseConfig")
    target_build_config_list_uuid = generate_uuid("targetBuildConfigList")
    project_config_list_uuid = generate_uuid("projectBuildConfigList")
    app_product_uuid = generate_uuid("appProduct")

    # 文件 UUIDs
    file_uuids = {}
    for f in swift_files + resource_files + asset_catalogs + folder_refs:
        file_uuids[f["rel_path"]] = generate_uuid(f"file_{f['rel_path']}")

    # 组 UUIDs
    group_uuids = {}
    all_dirs = set()
    for f in swift_files:
        d = f["dir"]
        if d:
            parts = d.split(os.sep)
            for i in range(len(parts)):
                all_dirs.add(os.sep.join(parts[:i+1]))

    for d in all_dirs:
        group_uuids[d] = generate_uuid(f"group_{d}")

    # 生成 pbxproj
    pbxproj_content = generate_pbxproj(
        root_object_uuid, main_group_uuid, products_group_uuid,
        sources_build_phase_uuid, resources_build_phase_uuid, frameworks_build_phase_uuid,
        target_uuid, debug_config_uuid, release_config_uuid,
        target_debug_config_uuid, target_release_config_uuid, target_build_config_list_uuid,
        project_config_list_uuid, app_product_uuid, file_uuids, group_uuids,
        swift_files, resource_files, asset_catalogs, folder_refs, all_dirs
    )

    pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
    with open(pbxproj_path, "w") as f:
        f.write(pbxproj_content)
    print(f"已生成: {pbxproj_path}")

    generate_xcschemes(xcodeproj_dir)
    print("Xcode 项目生成完成！")

def generate_pbxproj(root_object_uuid, main_group_uuid, products_group_uuid,
                       sources_build_phase_uuid, resources_build_phase_uuid, frameworks_build_phase_uuid,
                       target_uuid, debug_config_uuid, release_config_uuid,
                       target_debug_config_uuid, target_release_config_uuid, target_build_config_list_uuid,
                       project_config_list_uuid, app_product_uuid, file_uuids, group_uuids,
                       swift_files, resource_files, asset_catalogs, folder_refs, all_dirs):

    file_refs = []
    build_files = []
    source_build_files = []
    resource_build_files = []

    # 源文件
    for f in swift_files:
        file_uuid = file_uuids[f["rel_path"]]
        build_file_uuid = generate_uuid(f"buildfile_{f['rel_path']}")
        file_refs.append(f"\t\t{file_uuid} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f['name']}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_uuid} /* {f['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};")
        source_build_files.append(f"\t\t\t{build_file_uuid} /* {f['name']} in Sources */,")

    # 根资源文件
    for f in resource_files:
        file_uuid = file_uuids[f["rel_path"]]
        build_file_uuid = generate_uuid(f"buildfile_{f['rel_path']}")
        ext = os.path.splitext(f['name'])[1].lower()
        last_known_type = "image.png" if ext == ".png" else "file"
        file_refs.append(f"\t\t{file_uuid} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = {last_known_type}; path = {f['name']}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_uuid} /* {f['name']} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};")
        resource_build_files.append(f"\t\t\t{build_file_uuid} /* {f['name']} in Resources */,")

    # 资源目录 (xcassets)
    for f in asset_catalogs:
        file_uuid = file_uuids[f["rel_path"]]
        build_file_uuid = generate_uuid(f"buildfile_{f['rel_path']}")
        file_refs.append(f"\t\t{file_uuid} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {f['name']}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_uuid} /* {f['name']} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};")
        resource_build_files.append(f"\t\t\t{build_file_uuid} /* {f['name']} in Resources */,")

    # 文件夹引用 (Folder References) - 使用 folder 类型
    for f in folder_refs:
        file_uuid = file_uuids[f["rel_path"]]
        build_file_uuid = generate_uuid(f"buildfile_{f['rel_path']}")
        file_refs.append(f"\t\t{file_uuid} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = {f['name']}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{build_file_uuid} /* {f['name']} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};")
        resource_build_files.append(f"\t\t\t{build_file_uuid} /* {f['name']} in Resources */,")

    # 产品引用
    file_refs.append(f"\t\t{app_product_uuid} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

    # 构建组层次结构
    group_children = {}
    for d in all_dirs:
        group_children[d] = []
    group_children[""] = []

    # 将文件放入对应的组
    for f in swift_files:
        d = f["dir"]
        if d in group_children:
            group_children[d].append(file_uuids[f["rel_path"]])
        elif d == "":
            group_children[""].append(file_uuids[f["rel_path"]])

    for f in resource_files + asset_catalogs + folder_refs:
        d = f["dir"]
        if d in group_children:
            group_children[d].append(file_uuids[f["rel_path"]])
        elif d == "":
            group_children[""].append(file_uuids[f["rel_path"]])

    # 将子组放入父组
    for d in sorted(all_dirs, key=len, reverse=True):
        parent = os.path.dirname(d)
        if parent == "":
            group_children[""].append(group_uuids[d])
        elif parent in group_children:
            group_children[parent].append(group_uuids[d])

    # 产品组放入 mainGroup
    group_children[""].insert(0, products_group_uuid)

    # 构建组引用字符串
    group_refs = []

    # mainGroup
    main_children = group_children[""]
    children_formatted = ",\n\t\t\t\t".join(main_children)
    group_refs.append(f"\t\t{main_group_uuid} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{children_formatted}\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")

    # Products 组
    group_refs.append(f"\t\t{products_group_uuid} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_product_uuid} /* {PROJECT_NAME}.app */\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")

    # 其他组
    for d in sorted(all_dirs):
        g_uuid = group_uuids[d]
        g_name = os.path.basename(d)
        children = group_children.get(d, [])
        if not children:
            continue
        children_formatted = ",\n\t\t\t\t".join(children)
        group_refs.append(f"\t\t{g_uuid} /* {g_name} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{children_formatted}\n\t\t\t);\n\t\t\tpath = {g_name};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")

    # 生成完整的 pbxproj
    content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_build_phase_uuid} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{chr(10).join(group_refs)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_uuid} /* {PROJECT_NAME} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_build_config_list_uuid} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_build_phase_uuid} /* Sources */,
\t\t\t\t{frameworks_build_phase_uuid} /* Frameworks */,
\t\t\t\t{resources_build_phase_uuid} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {PROJECT_NAME};
\t\t\tproductName = {PROJECT_NAME};
\t\t\tproductReference = {app_product_uuid} /* {PROJECT_NAME}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{root_object_uuid} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_uuid} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {project_config_list_uuid} /* Build configuration list for PBXProject "{PROJECT_NAME}" */;
\t\t\tcompatibilityVersion = "Xcode 16.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = {main_group_uuid};
\t\t\tproductRefGroup = {products_group_uuid} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_uuid} /* {PROJECT_NAME} */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_build_phase_uuid} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(resource_build_files)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_build_phase_uuid} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(source_build_files)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_config_uuid} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_uuid} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{target_debug_config_uuid} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = \"\";
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = BabyBook;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.education";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIRequiresFullScreen = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{target_release_config_uuid} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = \"\";
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = BabyBook;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.education";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIRequiresFullScreen = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{project_config_list_uuid} /* Build configuration list for PBXProject "{PROJECT_NAME}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_uuid} /* Debug */,
\t\t\t\t{release_config_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_build_config_list_uuid} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{target_debug_config_uuid} /* Debug */,
\t\t\t\t{target_release_config_uuid} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {root_object_uuid} /* Project object */;
}}
"""
    return content

def generate_xcschemes(xcodeproj_dir):
    schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(schemes_dir, exist_ok=True)

    scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{generate_uuid('nativeTarget')}"
               BuildableName = "{PROJECT_NAME}.app"
               BlueprintName = "{PROJECT_NAME}"
               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{generate_uuid('nativeTarget')}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "IDEPreferLogStreaming"
            value = "YES"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{generate_uuid('nativeTarget')}"
            BuildableName = "{PROJECT_NAME}.app"
            BlueprintName = "{PROJECT_NAME}"
            ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

    scheme_path = os.path.join(schemes_dir, f"{PROJECT_NAME}.xcscheme")
    with open(scheme_path, "w") as f:
        f.write(scheme_content)
    print(f"已生成 scheme: {scheme_path}")

if __name__ == "__main__":
    generate_project()
