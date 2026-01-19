from setuptools import setup, find_packages

setup(
    name='cosmic-mouse',
    version='1.0.0',
    description='Cosmic Byte Firestorm Gaming Mouse Controller',
    author='Vineet Nair (electrondefuser)',
    packages=find_packages(),
    install_requires=[
        'pyusb>=1.2.1',
        'PyYAML>=6.0',
    ],
    entry_points={
        'console_scripts': [
            'cosmic-mouse=cosmic.__main__:main',
        ],
    },
    python_requires='>=3.8',
)
