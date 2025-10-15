#!/usr/bin/env python3
"""
Setup script for qwen-api package
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent.parent / "README.md"
long_description = ""
if readme_file.exists():
    with open(readme_file, "r", encoding="utf-8") as f:
        long_description = f.read()

setup(
    name="qwen-api",
    version="1.0.0",
    author="Zeeeepa",
    author_email="zeeeepa@gmail.com",
    description="OpenAI-compatible API server for Qwen language models",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Zeeeepa/qwen-api",
    packages=find_packages(),
    package_dir={"": "."},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
    install_requires=[
        "fastapi>=0.104.0",
        "uvicorn[standard]>=0.24.0",
        "httpx>=0.25.0",
        "playwright>=1.40.0",
        "pydantic>=2.0.0",
        "python-jose[cryptography]>=3.3.0",
        "python-dotenv>=1.0.0",
        "jsonschema>=4.20.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "ruff>=0.1.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "qwen-api=start:main",
            "qwen-token=qwen-api.get_qwen_token:main",
            "qwen-validate=qwen-api.validate_json:main",
            "qwen-check-token=qwen-api.check_jwt_expiry:main",
        ],
    },
    include_package_data=True,
    zip_safe=False,
)
