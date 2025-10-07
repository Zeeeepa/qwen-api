from setuptools import setup, find_packages

setup(
    name="qwen-api",
    version="1.0.0",
    description="OpenAI-compatible API server for Qwen AI",
    author="Qwen API Contributors",
    python_requires=">=3.8",
    packages=find_packages(),
    install_requires=[
        "fastapi>=0.104.0",
        "uvicorn[standard]>=0.24.0",
        "httpx>=0.25.0",
        "pydantic>=2.0.0",
        "python-multipart>=0.0.6",
    ],
    entry_points={
        "console_scripts": [
            "qwen-api=main:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)

