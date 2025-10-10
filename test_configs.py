import asyncio
import httpx
import json

async def test_request(config_name, body, headers):
    """Test a specific configuration"""
    print(f"\n{'='*60}")
    print(f"Testing: {config_name}")
    print(f"{'='*60}")
    print(f"Body: {json.dumps(body, indent=2)}")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                body.get('_url', ''),
                json={k: v for k, v in body.items() if k != '_url'},
                headers=headers
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            
            return response.status_code == 200 or response.json().get('success', False)
    except Exception as e:
        print(f"Error: {e}")
        return False

# This will be populated by the actual test
print("Test configuration script created")
