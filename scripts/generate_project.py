#!/usr/bin/env python3
"""Rebuild the checked-in, dependency-free Xcode project deterministically."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'DuoSound.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}
owner = json.loads((ROOT / 'release/readiness.json').read_text())['owner']

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

def add(identifier, **fields):
    key = uid(identifier)
    objects[key] = fields
    return key

def render(value):
    if isinstance(value, dict):
        return '{ ' + ' '.join(f'{json.dumps(str(k))} = {render(v)};' for k, v in value.items()) + ' }'
    if isinstance(value, list):
        return '( ' + ', '.join(render(v) for v in value) + (', ' if value else '') + ')'
    return json.dumps(str(value))

sources = sorted([*ROOT.glob('App/*.swift'), *ROOT.glob('Sources/DuoSoundCore/*.swift')])
children, builds = [], []
for path in sources:
    relative = str(path.relative_to(ROOT))
    ref = add(relative, isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path=relative, sourceTree='<group>')
    children.append(ref)
    builds.append(add(relative + ':build', isa='PBXBuildFile', fileRef=ref))
resources = []
for relative, kind, bundle in [('App/Info.plist', 'text.plist.xml', False), ('App/PrivacyInfo.xcprivacy', 'text.xml', True), ('App/PrivacySummary.txt', 'text', True), ('App/Assets.xcassets', 'folder.assetcatalog', True)]:
    ref = add(relative, isa='PBXFileReference', lastKnownFileType=kind, path=relative, sourceTree='<group>')
    children.append(ref)
    if bundle:
        resources.append(add(relative + ':build', isa='PBXBuildFile', fileRef=ref))
product = add('product', isa='PBXFileReference', explicitFileType='wrapper.application', path='DuoSound.app', sourceTree='BUILT_PRODUCTS_DIR')
products = add('products', isa='PBXGroup', children=[product], name='Products', sourceTree='<group>')
group = add('mainGroup', isa='PBXGroup', children=children + [products], sourceTree='<group>')
phases = [add('release-preflight', isa='PBXShellScriptBuildPhase', buildActionMask='2147483647',
              files=[], inputPaths=[], outputPaths=[], runOnlyForDeploymentPostprocessing='0',
              alwaysOutOfDate='1', name='Generate icon and guard App Store release', shellPath='/bin/sh',
              shellScript='set -eu\ncd "$SRCROOT"\n/usr/bin/python3 scripts/generate_assets.py\nif [ "$CONFIGURATION" = "AppStore" ]; then\n  /usr/bin/python3 scripts/release_check.py --submission\nfi\n')]
for name, kind, files in [('sources', 'PBXSourcesBuildPhase', builds), ('frameworks', 'PBXFrameworksBuildPhase', []), ('resources', 'PBXResourcesBuildPhase', resources)]:
    phases.append(add(name, isa=kind, buildActionMask='2147483647', files=files, runOnlyForDeploymentPostprocessing='0'))
project_configs, target_configs = [], []
for name in ['Debug', 'Release', 'Debug-Duo', 'Release-Duo', 'AppStore']:
    debug = name.startswith('Debug')
    duo = name.endswith('-Duo') or name == 'AppStore'
    shared = {'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'SDKROOT': 'iphoneos',
              # The public hinge interaction is runtime-bridged, so the
              # distribution candidate can be built with the supported stable
              # SDK while still running on iOS 27.1 Duo devices.
              'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SWIFT_VERSION': '5.0', 'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
              'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if debug else '-O', 'DEBUG_INFORMATION_FORMAT': 'dwarf' if debug else 'dwarf-with-dsym',
              'SWIFT_ACTIVE_COMPILATION_CONDITIONS': ' '.join(['$(inherited)'] + (['DEBUG'] if debug else []) + (['DUO_HINGE_SDK'] if duo else []) + (['APP_STORE_RELEASE'] if name == 'AppStore' else []))}
    project_configs.append(add('project:' + name, isa='XCBuildConfiguration', name=name, buildSettings=shared))
    target_settings = {
        'PRODUCT_NAME': 'DuoSound', 'PRODUCT_BUNDLE_IDENTIFIER': owner['bundle_id'], 'INFOPLIST_FILE': 'App/Info.plist',
        'GENERATE_INFOPLIST_FILE': 'NO', 'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
        'SUPPORTS_MACCATALYST': 'NO', 'CODE_SIGN_STYLE': 'Automatic', 'CURRENT_PROJECT_VERSION': '1', 'MARKETING_VERSION': '1.0',
        'LD_RUNPATH_SEARCH_PATHS': ['$(inherited)', '@executable_path/Frameworks'], 'ENABLE_PREVIEWS': 'YES', 'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
        'ENABLE_USER_SCRIPT_SANDBOXING': 'NO',
        'DUO_SUPPORT_URL': owner.get('support_url') or 'https://github.com/seichris/duo-sound/issues',
        'DUO_PRIVACY_URL': owner.get('privacy_url') or 'https://github.com/seichris/duo-sound/blob/main/docs/PRIVACY.md',
    }
    if owner.get('team_id'):
        target_settings['DEVELOPMENT_TEAM'] = owner['team_id']
    target_configs.append(add('target:' + name, isa='XCBuildConfiguration', name=name, buildSettings=target_settings))
project_list = add('project-configs', isa='XCConfigurationList', buildConfigurations=project_configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
target_list = add('target-configs', isa='XCConfigurationList', buildConfigurations=target_configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
target = add('target', isa='PBXNativeTarget', buildConfigurationList=target_list, buildPhases=phases, buildRules=[], dependencies=[],
             name='DuoSound', productName='DuoSound', productReference=product, productType='com.apple.product-type.application')
# UI smoke tests run only in the standard preview scheme, never as hardware evidence.
ui_builds = []
for path in sorted(ROOT.glob('UITests/*.swift')):
    relative = str(path.relative_to(ROOT))
    ref = add(relative, isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path=relative, sourceTree='<group>')
    objects[group]['children'].append(ref)
    ui_builds.append(add(relative + ':build', isa='PBXBuildFile', fileRef=ref))
ui_product = add('ui-product', isa='PBXFileReference', explicitFileType='wrapper.cfbundle', path='DuoSoundUITests.xctest', sourceTree='BUILT_PRODUCTS_DIR')
objects[products]['children'].append(ui_product)
ui_phases = []
for phase, kind, files in [('sources','PBXSourcesBuildPhase',ui_builds),('frameworks','PBXFrameworksBuildPhase',[]),('resources','PBXResourcesBuildPhase',[])]:
    ui_phases.append(add('ui-'+phase, isa=kind, buildActionMask='2147483647', files=files, runOnlyForDeploymentPostprocessing='0'))
ui_configs = []
for name in ['Debug', 'Release', 'Debug-Duo', 'Release-Duo', 'AppStore']:
    ui_configs.append(add('ui:'+name, isa='XCBuildConfiguration', name=name, buildSettings={
        'PRODUCT_NAME':'DuoSoundUITests', 'PRODUCT_BUNDLE_IDENTIFIER':owner['bundle_id']+'.uitests',
        'GENERATE_INFOPLIST_FILE':'YES', 'TEST_TARGET_NAME':'DuoSound', 'TARGETED_DEVICE_FAMILY':'1,2',
        'CODE_SIGN_STYLE':'Automatic', 'LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks','@loader_path/Frameworks']}))
ui_list = add('ui-configs', isa='XCConfigurationList', buildConfigurations=ui_configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
proxy = add('ui-proxy', isa='PBXContainerItemProxy', containerPortal=uid('project'), proxyType='1', remoteGlobalIDString=target, remoteInfo='DuoSound')
dependency = add('ui-dependency', isa='PBXTargetDependency', target=target, targetProxy=proxy)
ui_target = add('ui-target', isa='PBXNativeTarget', buildConfigurationList=ui_list, buildPhases=ui_phases,
                buildRules=[], dependencies=[dependency], name='DuoSoundUITests', productName='DuoSoundUITests',
                productReference=ui_product, productType='com.apple.product-type.bundle.ui-testing')
project = add('project', isa='PBXProject', attributes={'LastUpgradeCheck': '1600'}, buildConfigurationList=project_list,
              compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings='0', knownRegions=['en', 'Base'],
              mainGroup=group, productRefGroup=products, projectDirPath='', projectRoot='', targets=[target, ui_target])
content = '// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'
content += '\n'.join(f'  {key} = {render(value)};' for key, value in objects.items())
content += '\n };\n rootObject = ' + project + ';\n}\n'
(PROJECT / 'project.pbxproj').write_text(content)
schemes = PROJECT / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
for name, suffix in [('DuoSound', ''), ('DuoSound-DuoSDK', '-Duo'), ('DuoSound-AppStore', 'AppStore')]:
    ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="DuoSound.app" BlueprintName="DuoSound" ReferencedContainer="container:DuoSound.xcodeproj"/>'
    debug_config = 'AppStore' if suffix == 'AppStore' else 'Debug' + suffix
    release_config = 'AppStore' if suffix == 'AppStore' else 'Release' + suffix
    archive_config = 'AppStore' if suffix == 'AppStore' else release_config
    ui_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ui_target}" BuildableName="DuoSoundUITests.xctest" BlueprintName="DuoSoundUITests" ReferencedContainer="container:DuoSound.xcodeproj"/>'
    testables = f'<Testables><TestableReference skipped="NO">{ui_ref}</TestableReference></Testables>' if not suffix else '<Testables/>'
    (schemes / f'{name}.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="{debug_config}" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB">{testables}</TestAction>
<LaunchAction buildConfiguration="{debug_config}" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="{release_config}" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="{debug_config}"/>
<ArchiveAction buildConfiguration="{archive_config}" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated DuoSound.xcodeproj (preview, Duo SDK, and guarded App Store schemes).')
