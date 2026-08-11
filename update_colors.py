import os
import re

mapping = {
    'AppColors.primary': 'Theme.of(context).colorScheme.primary',
    'AppColors.onPrimary': 'Theme.of(context).colorScheme.onPrimary',
    'AppColors.primaryContainer': 'Theme.of(context).colorScheme.primaryContainer',
    'AppColors.onPrimaryContainer': 'Theme.of(context).colorScheme.onPrimaryContainer',
    
    'AppColors.secondary': 'Theme.of(context).colorScheme.secondary',
    'AppColors.onSecondary': 'Theme.of(context).colorScheme.onSecondary',
    'AppColors.secondaryContainer': 'Theme.of(context).colorScheme.secondaryContainer',
    'AppColors.onSecondaryContainer': 'Theme.of(context).colorScheme.onSecondaryContainer',
    
    'AppColors.tertiary': 'Theme.of(context).colorScheme.tertiary',
    'AppColors.onTertiary': 'Theme.of(context).colorScheme.onTertiary',
    'AppColors.tertiaryContainer': 'Theme.of(context).colorScheme.tertiaryContainer',
    'AppColors.onTertiaryContainer': 'Theme.of(context).colorScheme.onTertiaryContainer',
    
    'AppColors.error': 'Theme.of(context).colorScheme.error',
    'AppColors.onError': 'Theme.of(context).colorScheme.onError',
    'AppColors.errorContainer': 'Theme.of(context).colorScheme.errorContainer',
    'AppColors.onErrorContainer': 'Theme.of(context).colorScheme.onErrorContainer',
    
    'AppColors.background': 'Theme.of(context).scaffoldBackgroundColor',
    'AppColors.onBackground': 'Theme.of(context).colorScheme.onSurface',
    
    'AppColors.surface': 'Theme.of(context).colorScheme.surface',
    'AppColors.surfaceBase': 'Theme.of(context).colorScheme.surface',
    'AppColors.surfaceSubtle': 'Theme.of(context).colorScheme.surfaceContainerLow',
    'AppColors.surfaceMuted': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppColors.surfaceDim': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppColors.surfaceBright': 'Theme.of(context).colorScheme.surface',
    
    'AppColors.surfaceContainerLowest': 'Theme.of(context).colorScheme.surfaceContainerLowest',
    'AppColors.surfaceContainerLow': 'Theme.of(context).colorScheme.surfaceContainerLow',
    'AppColors.surfaceContainer': 'Theme.of(context).colorScheme.surfaceContainer',
    'AppColors.surfaceContainerHigh': 'Theme.of(context).colorScheme.surfaceContainerHigh',
    'AppColors.surfaceContainerHighest': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    
    'AppColors.onSurface': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.onSurfaceVariant': 'Theme.of(context).colorScheme.onSurfaceVariant',
    
    'AppColors.inverseSurface': 'Theme.of(context).colorScheme.inverseSurface',
    'AppColors.inverseOnSurface': 'Theme.of(context).colorScheme.onInverseSurface',
    'AppColors.inversePrimary': 'Theme.of(context).colorScheme.inversePrimary',
    
    'AppColors.outline': 'Theme.of(context).colorScheme.outline',
    'AppColors.outlineVariant': 'Theme.of(context).colorScheme.outlineVariant',
    
    'AppColors.splashBackground': 'Theme.of(context).colorScheme.surface',
}

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    # Sort keys by length descending to avoid partial matches
    for k in sorted(mapping.keys(), key=len, reverse=True):
        v = mapping[k]
        content = re.sub(r'\b' + re.escape(k) + r'\b', v, content)
        
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('/home/duke/Desktop/Duke/UBa/final-project/worktrackr/lib'):
    for file in files:
        if file.endswith('.dart') and file != 'app_colors.dart' and file != 'app_theme.dart':
            replace_in_file(os.path.join(root, file))

