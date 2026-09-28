import os
import re
import shutil

src_dir = '/tmp/EdgeDeckBar_clone/Sources/EdgeDeck'
dst_dir = '/Users/baraka/Desktop/SplitBar/Sources/SplitBar'

# 1. Clear out old sources
if os.path.exists(dst_dir):
    shutil.rmtree(dst_dir)
shutil.copytree(src_dir, dst_dir)

# 2. Rename files
for root, dirs, files in os.walk(dst_dir, topdown=False):
    for name in files:
        if 'EdgeDeck' in name:
            new_name = name.replace('EdgeDeck', 'SplitBar')
            os.rename(os.path.join(root, name), os.path.join(root, new_name))
    for name in dirs:
        if 'EdgeDeck' in name:
            new_name = name.replace('EdgeDeck', 'SplitBar')
            os.rename(os.path.join(root, name), os.path.join(root, new_name))

# 3. Text replacements in .swift files
for root, dirs, files in os.walk(dst_dir):
    for name in files:
        if name.endswith('.swift'):
            path = os.path.join(root, name)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace dev.edgedeck.app with com.baraka.splitbar
            content = content.replace('dev.edgedeck.app', 'com.baraka.splitbar')
            content = content.replace('dev.edgedeck.', 'com.baraka.splitbar.')
            
            # Rename the main module / classes
            content = content.replace('EdgeDeck', 'SplitBar')
            content = content.replace('edgedeck', 'splitbar')
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
