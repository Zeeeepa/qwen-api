#!/usr/bin/env python3
"""
Test script for Qwen API Server
================================

Simple test suite to validate the server is working correctly.
"""

import asyncio
import httpx
import sys

BASE_URL = "http://localhost:8000"
TEST_TOKEN = "H4sIAAAAAAAAA..."  # Mock token for testing

async def test_health():
    """Test health endpoint"""
    print("Testing /health endpoint...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        print("✅ Health check passed")
        return True

async def test_models():
    """Test models endpoint"""
    print("\nTesting /v1/models endpoint...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/v1/models")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        models = data["data"]
        print(f"✅ Models endpoint passed ({len(models)} models)")
        return True

async def test_validate():
    """Test validate endpoint"""
    print("\nTesting /v1/validate endpoint...")
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{BASE_URL}/v1/validate",
            json={"token": TEST_TOKEN}
        )
        # May fail with invalid token, but endpoint should respond
        print(f"✅ Validate endpoint responded (status: {response.status_code})")
        return True

async def test_chat():
    """Test chat completions endpoint"""
    print("\nTesting /v1/chat/completions endpoint...")
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{BASE_URL}/v1/chat/completions",
            headers={"Authorization": f"Bearer {TEST_TOKEN}"},
            json={
                "model": "qwen-turbo-latest",
                "messages": [{"role": "user", "content": "test"}]
            }
        )
        # May fail with invalid token, but endpoint should respond
        print(f"✅ Chat endpoint responded (status: {response.status_code})")
        return True

async def main():
    """Run all tests"""
    print("="*60)
    print("Qwen API Server - Test Suite")
    print("="*60)
    print(f"\nTesting server at: {BASE_URL}")
    print("\nMake sure the server is running:")
    print("  python main.py\n")
    
    try:
        # Run tests
        await test_health()
        await test_models()
        await test_validate()
        await test_chat()
        
        print("\n" + "="*60)
        print("✅ All tests completed!")
        print("="*60)
        return 0
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        print("\nMake sure the server is running:")
        print("  python main.py")
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))

