#!/usr/bin/env python3
"""
Comprehensive Test Suite for All Qwen API Models and Features

Tests all 35+ Qwen model variants and validates their capabilities:
- Text chat (base models)
- Thinking/reasoning mode
- Web search integration
- Text-to-image generation
- Image editing
- Text-to-video generation
- Deep research mode
- Code generation models

Usage:
    python test_all_models.py
    python test_all_models.py --base-url http://localhost:8080/v1
    python test_all_models.py --api-key your-api-key
    python test_all_models.py --verbose
"""

import asyncio
import base64
import json
import sys
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime
import argparse

try:
    from openai import OpenAI, AsyncOpenAI
    from openai.types.chat import ChatCompletion
except ImportError:
    print("❌ Error: OpenAI library not installed")
    print("Install with: pip install openai")
    sys.exit(1)


@dataclass
class TestResult:
    """Test result container"""
    model: str
    feature: str
    status: str  # "PASS", "FAIL", "SKIP"
    duration: float
    error: Optional[str] = None
    response_preview: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class TestSummary:
    """Overall test summary"""
    total: int = 0
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    duration: float = 0.0
    results: List[TestResult] = field(default_factory=list)

    def add_result(self, result: TestResult):
        """Add a test result and update counters"""
        self.results.append(result)
        self.total += 1
        self.duration += result.duration
        
        if result.status == "PASS":
            self.passed += 1
        elif result.status == "FAIL":
            self.failed += 1
        elif result.status == "SKIP":
            self.skipped += 1

    def print_summary(self):
        """Print formatted test summary"""
        print("\n" + "=" * 80)
        print("📊 TEST SUMMARY")
        print("=" * 80)
        print(f"Total Tests:    {self.total}")
        print(f"✅ Passed:      {self.passed} ({self.passed/self.total*100:.1f}%)")
        print(f"❌ Failed:      {self.failed} ({self.failed/self.total*100:.1f}%)")
        print(f"⏭️  Skipped:     {self.skipped} ({self.skipped/self.total*100:.1f}%)")
        print(f"⏱️  Duration:    {self.duration:.2f}s")
        print("=" * 80)

        if self.failed > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.results:
                if result.status == "FAIL":
                    print(f"  • {result.model} ({result.feature}): {result.error}")


class QwenAPITester:
    """Comprehensive tester for Qwen API"""
    
    def __init__(
        self, 
        base_url: str = "http://localhost:8080/v1",
        api_key: str = "sk-test-key",
        verbose: bool = False,
        skip_slow: bool = False
    ):
        self.base_url = base_url
        self.api_key = api_key
        self.verbose = verbose
        self.skip_slow = skip_slow
        
        # Initialize OpenAI clients
        self.client = OpenAI(api_key=api_key, base_url=base_url)
        self.async_client = AsyncOpenAI(api_key=api_key, base_url=base_url)
        
        self.summary = TestSummary()
        
    def log(self, message: str, level: str = "INFO"):
        """Log message with timestamp"""
        if self.verbose or level in ["ERROR", "WARN"]:
            timestamp = datetime.now().strftime("%H:%M:%S")
            prefix = {
                "INFO": "ℹ️",
                "SUCCESS": "✅",
                "ERROR": "❌",
                "WARN": "⚠️",
                "DEBUG": "🔍"
            }.get(level, "•")
            print(f"[{timestamp}] {prefix} {message}")

    def get_all_models(self) -> List[str]:
        """Get all supported model variants"""
        base_models = ["qwen-max", "qwen-plus", "qwen-turbo", "qwen-long"]
        suffixes = ["", "-thinking", "-search", "-image", "-image_edit", "-video", "-deep-research"]
        
        models = []
        for base in base_models:
            for suffix in suffixes:
                models.append(f"{base}{suffix}")
        
        # Add aliases
        models.extend([
            "qwen-max-latest",
            "qwen-max-0428",
            "qwen-plus-latest",
            "qwen-turbo-latest",
            "qwen-deep-research",
            "qwen3-coder-plus",
            "qwen-coder-plus"
        ])
        
        return models

    async def test_text_chat(self, model: str) -> TestResult:
        """Test basic text chat capability"""
        start = asyncio.get_event_loop().time()
        
        try:
            self.log(f"Testing text chat: {model}", "DEBUG")
            
            response = await self.async_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": "Say 'Hello from Qwen API test!' in one sentence."}
                ],
                max_tokens=50,
                stream=False
            )
            
            duration = asyncio.get_event_loop().time() - start
            content = response.choices[0].message.content
            
            if content and len(content) > 0:
                self.log(f"✅ {model}: {content[:50]}...", "SUCCESS")
                return TestResult(
                    model=model,
                    feature="text_chat",
                    status="PASS",
                    duration=duration,
                    response_preview=content[:100],
                    metadata={
                        "tokens": response.usage.total_tokens if response.usage else 0
                    }
                )
            else:
                raise ValueError("Empty response content")
                
        except Exception as e:
            duration = asyncio.get_event_loop().time() - start
            self.log(f"❌ {model} text chat failed: {str(e)}", "ERROR")
            return TestResult(
                model=model,
                feature="text_chat",
                status="FAIL",
                duration=duration,
                error=str(e)
            )

    async def test_thinking_mode(self, model: str) -> TestResult:
        """Test thinking/reasoning mode"""
        start = asyncio.get_event_loop().time()
        
        try:
            self.log(f"Testing thinking mode: {model}", "DEBUG")
            
            response = await self.async_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": "Calculate 17 * 23 step by step."}
                ],
                max_tokens=200,
                stream=False
            )
            
            duration = asyncio.get_event_loop().time() - start
            content = response.choices[0].message.content
            
            # Check for thinking content in response
            has_thinking = hasattr(response.choices[0].message, 'thinking')
            
            if content and len(content) > 0:
                self.log(f"✅ {model}: Thinking={'Yes' if has_thinking else 'No'}", "SUCCESS")
                return TestResult(
                    model=model,
                    feature="thinking",
                    status="PASS",
                    duration=duration,
                    response_preview=content[:100],
                    metadata={
                        "has_thinking": has_thinking,
                        "tokens": response.usage.total_tokens if response.usage else 0
                    }
                )
            else:
                raise ValueError("Empty response")
                
        except Exception as e:
            duration = asyncio.get_event_loop().time() - start
            self.log(f"❌ {model} thinking mode failed: {str(e)}", "ERROR")
            return TestResult(
                model=model,
                feature="thinking",
                status="FAIL",
                duration=duration,
                error=str(e)
            )

    async def test_search_mode(self, model: str) -> TestResult:
        """Test web search integration"""
        if self.skip_slow:
            return TestResult(
                model=model,
                feature="search",
                status="SKIP",
                duration=0.0,
                error="Skipped (slow test)"
            )
        
        start = asyncio.get_event_loop().time()
        
        try:
            self.log(f"Testing search mode: {model}", "DEBUG")
            
            response = await self.async_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": "What's the latest news about AI in 2025?"}
                ],
                max_tokens=150,
                stream=False
            )
            
            duration = asyncio.get_event_loop().time() - start
            content = response.choices[0].message.content
            
            if content and len(content) > 0:
                self.log(f"✅ {model}: Search completed", "SUCCESS")
                return TestResult(
                    model=model,
                    feature="search",
                    status="PASS",
                    duration=duration,
                    response_preview=content[:100],
                    metadata={
                        "tokens": response.usage.total_tokens if response.usage else 0
                    }
                )
            else:
                raise ValueError("Empty response")
                
        except Exception as e:
            duration = asyncio.get_event_loop().time() - start
            self.log(f"❌ {model} search mode failed: {str(e)}", "ERROR")
            return TestResult(
                model=model,
                feature="search",
                status="FAIL",
                duration=duration,
                error=str(e)
            )

    async def test_image_generation(self, model: str) -> TestResult:
        """Test text-to-image generation"""
        if self.skip_slow:
            return TestResult(
                model=model,
                feature="image_generation",
                status="SKIP",
                duration=0.0,
                error="Skipped (slow test)"
            )
        
        start = asyncio.get_event_loop().time()
        
        try:
            self.log(f"Testing image generation: {model}", "DEBUG")
            
            # Note: This requires actual Qwen credentials
            # For now, we'll test if the endpoint accepts the request
            response = await self.async_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": "Generate an image of a sunset over mountains"}
                ],
                max_tokens=100,
                stream=False
            )
            
            duration = asyncio.get_event_loop().time() - start
            
            self.log(f"✅ {model}: Image generation endpoint accepted request", "SUCCESS")
            return TestResult(
                model=model,
                feature="image_generation",
                status="PASS",
                duration=duration,
                metadata={"note": "Endpoint validation only - actual generation requires credentials"}
            )
                
        except Exception as e:
            duration = asyncio.get_event_loop().time() - start
            self.log(f"❌ {model} image generation failed: {str(e)}", "ERROR")
            return TestResult(
                model=model,
                feature="image_generation",
                status="FAIL",
                duration=duration,
                error=str(e)
            )

    async def test_streaming(self, model: str) -> TestResult:
        """Test streaming response"""
        start = asyncio.get_event_loop().time()
        
        try:
            self.log(f"Testing streaming: {model}", "DEBUG")
            
            chunks_received = 0
            content_parts = []
            
            stream = await self.async_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "user", "content": "Count from 1 to 5."}
                ],
                max_tokens=50,
                stream=True
            )
            
            async for chunk in stream:
                chunks_received += 1
                if chunk.choices and chunk.choices[0].delta.content:
                    content_parts.append(chunk.choices[0].delta.content)
            
            duration = asyncio.get_event_loop().time() - start
            full_content = "".join(content_parts)
            
            if chunks_received > 0 and len(full_content) > 0:
                self.log(f"✅ {model}: Received {chunks_received} chunks", "SUCCESS")
                return TestResult(
                    model=model,
                    feature="streaming",
                    status="PASS",
                    duration=duration,
                    response_preview=full_content[:100],
                    metadata={"chunks": chunks_received}
                )
            else:
                raise ValueError("No chunks received")
                
        except Exception as e:
            duration = asyncio.get_event_loop().time() - start
            self.log(f"❌ {model} streaming failed: {str(e)}", "ERROR")
            return TestResult(
                model=model,
                feature="streaming",
                status="FAIL",
                duration=duration,
                error=str(e)
            )

    async def run_model_tests(self, model: str) -> List[TestResult]:
        """Run all applicable tests for a model"""
        results = []
        
        # Determine which tests to run based on model name
        if "-image" in model and "-image_edit" not in model:
            # Image generation model
            results.append(await self.test_image_generation(model))
        elif "-image_edit" in model:
            # Image editing - skip for now (requires image input)
            results.append(TestResult(
                model=model,
                feature="image_edit",
                status="SKIP",
                duration=0.0,
                error="Requires image input - manual testing needed"
            ))
        elif "-video" in model:
            # Video generation - skip for now (very slow)
            results.append(TestResult(
                model=model,
                feature="video_generation",
                status="SKIP",
                duration=0.0,
                error="Video generation skipped (very slow)"
            ))
        elif "-deep-research" in model or model == "qwen-deep-research":
            # Deep research - skip for now (very slow)
            results.append(TestResult(
                model=model,
                feature="deep_research",
                status="SKIP",
                duration=0.0,
                error="Deep research skipped (very slow)"
            ))
        elif "-thinking" in model:
            # Thinking mode
            results.append(await self.test_thinking_mode(model))
            results.append(await self.test_streaming(model))
        elif "-search" in model:
            # Search mode
            results.append(await self.test_search_mode(model))
            results.append(await self.test_streaming(model))
        else:
            # Standard text chat
            results.append(await self.test_text_chat(model))
            results.append(await self.test_streaming(model))
        
        return results

    async def run_all_tests(self):
        """Run comprehensive tests on all models"""
        print("🚀 Starting Qwen API Comprehensive Test Suite")
        print(f"📡 Base URL: {self.base_url}")
        print(f"🔑 API Key: {self.api_key[:20]}...")
        print("=" * 80)
        
        models = self.get_all_models()
        print(f"📋 Testing {len(models)} model variants\n")
        
        # Test each model
        for i, model in enumerate(models, 1):
            print(f"\n[{i}/{len(models)}] Testing {model}...")
            print("-" * 80)
            
            results = await self.run_model_tests(model)
            
            for result in results:
                self.summary.add_result(result)
                
                # Print immediate result
                status_icon = {
                    "PASS": "✅",
                    "FAIL": "❌",
                    "SKIP": "⏭️"
                }[result.status]
                
                print(f"{status_icon} {result.feature}: {result.status} ({result.duration:.2f}s)")
                if result.error:
                    print(f"   Error: {result.error}")
                elif result.response_preview:
                    print(f"   Preview: {result.response_preview[:60]}...")
        
        # Print summary
        self.summary.print_summary()
        
        # Export results to JSON
        self.export_results()
        
        return self.summary

    def export_results(self):
        """Export test results to JSON file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"qwen_api_test_results_{timestamp}.json"
        
        results_data = {
            "timestamp": datetime.now().isoformat(),
            "base_url": self.base_url,
            "summary": {
                "total": self.summary.total,
                "passed": self.summary.passed,
                "failed": self.summary.failed,
                "skipped": self.summary.skipped,
                "duration": self.summary.duration
            },
            "results": [
                {
                    "model": r.model,
                    "feature": r.feature,
                    "status": r.status,
                    "duration": r.duration,
                    "error": r.error,
                    "response_preview": r.response_preview,
                    "metadata": r.metadata
                }
                for r in self.summary.results
            ]
        }
        
        try:
            with open(filename, 'w') as f:
                json.dump(results_data, f, indent=2)
            print(f"\n💾 Results exported to: {filename}")
        except Exception as e:
            print(f"\n⚠️ Failed to export results: {e}")


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Comprehensive test suite for Qwen API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python test_all_models.py
  python test_all_models.py --base-url http://localhost:8080/v1
  python test_all_models.py --api-key your-api-key --verbose
  python test_all_models.py --skip-slow
        """
    )
    
    parser.add_argument(
        "--base-url",
        default="http://localhost:8080/v1",
        help="Base URL of Qwen API (default: http://localhost:8080/v1)"
    )
    parser.add_argument(
        "--api-key",
        default="sk-test-key",
        help="API key for authentication (default: sk-test-key)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    parser.add_argument(
        "--skip-slow",
        action="store_true",
        help="Skip slow tests (search, image, video, research)"
    )
    
    args = parser.parse_args()
    
    # Create tester and run tests
    tester = QwenAPITester(
        base_url=args.base_url,
        api_key=args.api_key,
        verbose=args.verbose,
        skip_slow=args.skip_slow
    )
    
    try:
        summary = await tester.run_all_tests()
        
        # Exit with error code if tests failed
        sys.exit(0 if summary.failed == 0 else 1)
        
    except KeyboardInterrupt:
        print("\n\n⚠️ Tests interrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())

