import os
from importlib import import_module

lp = import_module('lazurite.project.project')

out = os.path.join('pack', 'renderer', 'materials')
os.makedirs(out, exist_ok=True)

lp.compile(
    project_path='.',
    profiles=['android'],
    output_folder=out,
    material_patterns=[],
    shaderc_path=os.path.abspath(os.path.join('tools', 'shaderc')),
    defines=[]
)
