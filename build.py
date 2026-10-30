import json
import os
import shutil
from importlib import import_module

lp = import_module('lazurite.project.project')

stage = '.stage'
skip = {'pack', 'tools', 'tmp', 'common'}

defaults = {
    'SunDirection': [1.0, 0.0, 0.0, 0.0],
    'CloudColor': [1.0, 1.0, 1.0, 1.0],
    'SkyColor': [1.0, 1.0, 1.0, 1.0],
    'FogColor': [1.0, 1.0, 1.0, 1.0],
}

extra_uniforms = {
    'Weather': ['ViewPositionAndTime'],
    'Stars': ['ViewPositionAndTime'],
}

if os.path.isdir(stage):
    shutil.rmtree(stage)
os.makedirs(stage)

for name in os.listdir('.'):
    if name.startswith('.') or name in skip or not os.path.isdir(name):
        continue
    shutil.copytree(name, os.path.join(stage, name))
shutil.copy('project.json', stage)

with open(os.path.join('common', 'material.json')) as f:
    common = json.load(f)

for name in os.listdir(stage):
    folder = os.path.join(stage, name)
    if not os.path.isfile(os.path.join(folder, 'config.json')):
        continue

    with open(os.path.join(folder, 'material.json'), 'w') as f:
        json.dump(common, f, indent=2)

    uniforms = os.path.join(folder, 'uniforms')
    os.makedirs(uniforms, exist_ok=True)

    for uniform in common.get('uniform_overrides', {}):
        entry = {
            'name': uniform,
            'type': 'vec4',
            'count': 1,
            'default': defaults.get(uniform, [0.0, 0.0, 0.0, 0.0]),
        }
        with open(os.path.join(uniforms, uniform + '.json'), 'w') as f:
            json.dump(entry, f, indent=2)

    for uniform in extra_uniforms.get(name, []):
        entry = {
            'name': uniform,
            'type': 'vec4',
            'count': 1,
            'default': [0.0, 0.0, 0.0, 0.0],
        }
        with open(os.path.join(uniforms, uniform + '.json'), 'w') as f:
            json.dump(entry, f, indent=2)

out = os.path.join('pack', 'renderer', 'materials')
os.makedirs(out, exist_ok=True)

lp.compile(
    project_path=stage,
    profiles=[os.environ.get('PROFILE', 'android')],
    output_folder=out,
    material_patterns=[],
    shaderc_path=os.path.abspath(os.path.join('tools', 'shaderc')),
    defines=[]
)
