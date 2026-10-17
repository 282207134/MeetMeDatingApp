#!/usr/bin/env python3
"""Generate the small, dependency-free Xcode project from checked-in Swift sources."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
objects = {}
counter = 0

def obj(body):
    global counter
    counter += 1
    key = f'A{counter:023X}'
    objects[key] = body
    return key

def q(value):
    return json.dumps(str(value))

def ids(values):
    return '(' + ', '.join(values) + (',' if values else '') + ')'

def settings(values):
    return '{ ' + ' '.join(f'{key} = {q(value)};' for key, value in values.items()) + ' }'

def config_list(values):
    configs = []
    for name in ('Debug', 'Release'):
        current = dict(values)
        current['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if name == 'Debug' else '-O'
        if name == 'Debug': current['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
        configs.append(obj(f'isa = XCBuildConfiguration; buildSettings = {settings(current)}; name = {name};'))
    return obj(f'isa = XCConfigurationList; buildConfigurations = {ids(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

product_refs = []
source_groups = []
targets = []

def target(name, directory, product_type, product_ext, extra, app_target=None):
    refs = []
    build_files = []
    for path in sorted((ROOT / directory).glob('*.swift')):
        ref = obj(f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(path.name)}; sourceTree = "<group>";')
        refs.append(ref)
        build_files.append(obj(f'isa = PBXBuildFile; fileRef = {ref};'))
    resource_files = []
    if name == 'MeetMe':
        ref = obj('isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
        refs.append(ref)
        resource_files.append(obj(f'isa = PBXBuildFile; fileRef = {ref};'))
    source_groups.append(obj(f'isa = PBXGroup; children = {ids(refs)}; path = {q(directory)}; sourceTree = "<group>";'))
    product = obj(f'isa = PBXFileReference; explicitFileType = {q("wrapper.application" if name == "MeetMe" else "wrapper.cfbundle")}; includeInIndex = 0; path = {q(name + product_ext)}; sourceTree = BUILT_PRODUCTS_DIR;')
    product_refs.append(product)
    sources = obj(f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {ids(build_files)}; runOnlyForDeploymentPostprocessing = 0;')
    frameworks = obj('isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    resources = obj(f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {ids(resource_files)}; runOnlyForDeploymentPostprocessing = 0;')
    values = {
        'PRODUCT_NAME': '$(TARGET_NAME)', 'PRODUCT_BUNDLE_IDENTIFIER': 'dev.meetme.localdemo' + ('' if name == 'MeetMe' else '.' + name.lower()),
        'SWIFT_VERSION': '5.0', 'IPHONEOS_DEPLOYMENT_TARGET': '18.0', 'SDKROOT': 'iphoneos',
        'TARGETED_DEVICE_FAMILY': '1', 'GENERATE_INFOPLIST_FILE': 'YES', 'CODE_SIGN_STYLE': 'Automatic',
        'CURRENT_PROJECT_VERSION': '1', 'MARKETING_VERSION': '1.0',
    }
    values.update(extra)
    dependencies = []
    if app_target:
        dependencies.append(obj(f'isa = PBXTargetDependency; target = {app_target};'))
    target_id = obj(f'isa = PBXNativeTarget; buildConfigurationList = {config_list(values)}; buildPhases = {ids([sources, frameworks, resources])}; buildRules = (); dependencies = {ids(dependencies)}; name = {q(name)}; productName = {q(name)}; productReference = {product}; productType = {q(product_type)};')
    targets.append((target_id, name, product))
    return target_id

app = target('MeetMe', 'MeetMe', 'com.apple.product-type.application', '.app', {
    'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon', 'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME': 'AccentColor',
    'INFOPLIST_KEY_CFBundleDisplayName': 'Meetme', 'INFOPLIST_KEY_LSApplicationCategoryType': 'public.app-category.social-networking',
    'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES', 'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations': 'UIInterfaceOrientationPortrait',
    'INFOPLIST_KEY_ITSAppUsesNonExemptEncryption': 'NO', 'ENABLE_PREVIEWS': 'YES',
})
target('MeetMeTests', 'MeetMeTests', 'com.apple.product-type.bundle.unit-test', '.xctest', {
    'TEST_HOST': '$(BUILT_PRODUCTS_DIR)/MeetMe.app/MeetMe', 'BUNDLE_LOADER': '$(TEST_HOST)',
}, app)
target('MeetMeUITests', 'MeetMeUITests', 'com.apple.product-type.bundle.ui-testing', '.xctest', {'TEST_TARGET_NAME': 'MeetMe'}, app)
products_group = obj(f'isa = PBXGroup; children = {ids(product_refs)}; name = Products; sourceTree = "<group>";')
main_group = obj(f'isa = PBXGroup; children = {ids(source_groups + [products_group])}; sourceTree = "<group>";')
project_configs = config_list({'CLANG_ENABLE_MODULES': 'YES', 'SWIFT_VERSION': '5.0', 'IPHONEOS_DEPLOYMENT_TARGET': '18.0', 'ENABLE_TESTABILITY': 'YES', 'DEBUG_INFORMATION_FORMAT': 'dwarf'})
attributes = ' '.join(f'{tid} = {{ CreatedOnToolsVersion = 26.0; ' + (f'TestTargetID = {app}; ' if name != 'MeetMe' else '') + '};' for tid, name, _ in targets)
project = obj(f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2600; TargetAttributes = {{ {attributes} }}; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 15.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main_group}; productRefGroup = {products_group}; projectDirPath = ""; projectRoot = ""; targets = {ids([t[0] for t in targets])};')
folder = ROOT / 'MeetMe.xcodeproj'
folder.mkdir(exist_ok=True)
body = '// !$*UTF8*$!\n{\n archiveVersion = 1; classes = {}; objectVersion = 60;\n objects = {\n'
body += '\n'.join(f'  {key} = {{ {value} }};' for key, value in objects.items())
body += f'\n }};\n rootObject = {project};\n}}\n'
(folder / 'project.pbxproj').write_text(body)
scheme_folder = folder / 'xcshareddata' / 'xcschemes'
scheme_folder.mkdir(parents=True, exist_ok=True)
def reference(t):
    tid, name, _ = t
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tid}" BuildableName="{name}{".app" if name == "MeetMe" else ".xctest"}" BlueprintName="{name}" ReferencedContainer="container:MeetMe.xcodeproj"/>'
entries = ''.join(f'<BuildActionEntry buildForTesting="YES" buildForRunning="{"YES" if t[1] == "MeetMe" else "NO"}" buildForProfiling="{"YES" if t[1] == "MeetMe" else "NO"}" buildForArchiving="{"YES" if t[1] == "MeetMe" else "NO"}" buildForAnalyzing="YES">{reference(t)}</BuildActionEntry>' for t in targets)
testables = ''.join(f'<TestableReference skipped="NO" parallelizable="NO">{reference(t)}</TestableReference>' for t in targets[1:])
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>{entries}</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>{testables}</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(targets[0])}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(targets[0])}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(scheme_folder / 'MeetMe.xcscheme').write_text(scheme)
print('Generated MeetMe.xcodeproj with application, model tests, and UI tests.')
