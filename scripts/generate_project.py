#!/usr/bin/env python3
"""Rebuild the checked-in, dependency-free Xcode project deterministically."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'DuoSound.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}

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
for relative, kind, bundle in [('App/Info.plist', 'text.plist.xml', False), ('App/PrivacyInfo.xcprivacy', 'text.xml', True)]:
    ref = add(relative, isa='PBXFileReference', lastKnownFileType=kind, path=relative, sourceTree='<group>')
    children.append(ref)
    if bundle:
        resources.append(add(relative + ':build', isa='PBXBuildFile', fileRef=ref))
product = add('product', isa='PBXFileReference', explicitFileType='wrapper.application', path='DuoSound.app', sourceTree='BUILT_PRODUCTS_DIR')
products = add('products', isa='PBXGroup', children=[product], name='Products', sourceTree='<group>')
group = add('mainGroup', isa='PBXGroup', children=children + [products], sourceTree='<group>')
phases = []
for name, kind, files in [('sources', 'PBXSourcesBuildPhase', builds), ('frameworks', 'PBXFrameworksBuildPhase', []), ('resources', 'PBXResourcesBuildPhase', resources)]:
    phases.append(add(name, isa=kind, buildActionMask='2147483647', files=files, runOnlyForDeploymentPostprocessing='0'))
project_configs, target_configs = [], []
for name in ['Debug', 'Release', 'Debug-Duo', 'Release-Duo']:
    debug = name.startswith('Debug')
    duo = name.endswith('-Duo')
    shared = {'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'SDKROOT': 'iphoneos',
              'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SWIFT_VERSION': '5.0', 'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
              'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if debug else '-O', 'DEBUG_INFORMATION_FORMAT': 'dwarf' if debug else 'dwarf-with-dsym',
              'SWIFT_ACTIVE_COMPILATION_CONDITIONS': ' '.join(['$(inherited)'] + (['DEBUG'] if debug else []) + (['DUO_HINGE_SDK'] if duo else []))}
    project_configs.append(add('project:' + name, isa='XCBuildConfiguration', name=name, buildSettings=shared))
    target_configs.append(add('target:' + name, isa='XCBuildConfiguration', name=name, buildSettings={
        'PRODUCT_NAME': 'DuoSound', 'PRODUCT_BUNDLE_IDENTIFIER': 'com.seichris.duosound', 'INFOPLIST_FILE': 'App/Info.plist',
        'GENERATE_INFOPLIST_FILE': 'NO', 'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
        'SUPPORTS_MACCATALYST': 'NO', 'CODE_SIGN_STYLE': 'Automatic', 'CURRENT_PROJECT_VERSION': '1', 'MARKETING_VERSION': '0.1.0',
        'LD_RUNPATH_SEARCH_PATHS': ['$(inherited)', '@executable_path/Frameworks'], 'ENABLE_PREVIEWS': 'YES',
    }))
project_list = add('project-configs', isa='XCConfigurationList', buildConfigurations=project_configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
target_list = add('target-configs', isa='XCConfigurationList', buildConfigurations=target_configs, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')
target = add('target', isa='PBXNativeTarget', buildConfigurationList=target_list, buildPhases=phases, buildRules=[], dependencies=[],
             name='DuoSound', productName='DuoSound', productReference=product, productType='com.apple.product-type.application')
project = add('project', isa='PBXProject', attributes={'LastUpgradeCheck': '1600'}, buildConfigurationList=project_list,
              compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings='0', knownRegions=['en', 'Base'],
              mainGroup=group, productRefGroup=products, projectDirPath='', projectRoot='', targets=[target])
content = '// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'
content += '\n'.join(f'  {key} = {render(value)};' for key, value in objects.items())
content += '\n };\n rootObject = ' + project + ';\n}\n'
(PROJECT / 'project.pbxproj').write_text(content)
schemes = PROJECT / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
for name, suffix in [('DuoSound', ''), ('DuoSound-DuoSDK', '-Duo')]:
    ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="DuoSound.app" BlueprintName="DuoSound" ReferencedContainer="container:DuoSound.xcodeproj"/>'
    (schemes / f'{name}.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug{suffix}" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB"/>
<LaunchAction buildConfiguration="Debug{suffix}" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release{suffix}" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug{suffix}"/>
<ArchiveAction buildConfiguration="Release{suffix}" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated DuoSound.xcodeproj (standard and opt-in Duo SDK schemes).')
