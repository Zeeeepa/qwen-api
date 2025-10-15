#!/usr/bin/env python

"""
Token池管理器
实现AUTH_TOKEN的轮询机制，提供负载均衡和容错功能
"""

import asyncio
import time
from dataclasses import dataclass
from threading import Lock
from typing import Dict, List, Optional

import httpx

from logger import logger


@dataclass
class TokenStatus:
    """Token状态信息"""
    token: str
    is_available: bool = True
    failure_count: int = 0
    last_failure_time: float = 0.0
    last_success_time: float = 0.0
    total_requests: int = 0
    successful_requests: int = 0
    token_type: str = "unknown"  # "user", "guest", "unknown"

    @property
    def success_rate(self) -> float:
        """成功率"""
        if self.total_requests == 0:
            return 1.0
        return self.successful_requests / self.total_requests

    @property
    def is_healthy(self) -> bool:
        """
        是否健康

        健康的定义：
        1. 必须是认证用户token (token_type = "user")
        2. 当前可用 (is_available = True)
        3. 成功率 >= 50% 或者总请求数 <= 3（新token容错）

        注意：guest token不应该在AUTH_TOKENS中
        """
        # guest token永远不健康
        if self.token_type == "guest":
            return False

        # 未知类型token不健康
        if self.token_type != "user":
            return False

        # 不可用的token不健康
        if not self.is_available:
            return False

        # 对于认证用户token，基于成功率判断
        # 新token或请求数很少时，给予容错
        if self.total_requests <= 3:
            return self.failure_count == 0

        # 基于成功率判断健康状态
        return self.success_rate >= 0.5


class TokenPool:
    """Token池管理器"""

    def __init__(self, tokens: List[str], failure_threshold: int = 3, recovery_timeout: int = 1800):
        """
        初始化Token池

        Args:
            tokens: token列表
            failure_threshold: 失败阈值，超过此次数将标记为不可用
            recovery_timeout: 恢复超时时间（秒），失败token在此时间后重新尝试
        """
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self._lock = Lock()
        self._current_index = 0

        # 初始化token状态
        self.token_statuses: Dict[str, TokenStatus] = {}
        original_count = len(tokens)
        unique_tokens = []

        # 去重处理
        for token in tokens:
            if token and token not in self.token_statuses:  # 过滤空token和重复token
                # 预设为认证用户token，因为这些是用户手动配置的token
                self.token_statuses[token] = TokenStatus(token=token, token_type="user")
                unique_tokens.append(token)

        duplicate_count = original_count - len(unique_tokens)
        if duplicate_count > 0:
            logger.warning(f"⚠️ 检测到 {duplicate_count} 个重复token，已自动去重")

        if not self.token_statuses:
            logger.warning("⚠️ Token池为空，将依赖匿名模式")
        # else:
        #     logger.info(f"🔧 初始化Token池，共 {len(self.token_statuses)} 个token")

    def get_next_token(self) -> Optional[str]:
        """
        获取下一个可用的token（轮询算法）

        Returns:
            可用的token，如果没有可用token则返回None
        """
        with self._lock:
            if not self.token_statuses:
                return None

            available_tokens = self._get_available_tokens()
            if not available_tokens:
                # 尝试恢复过期的失败token
                self._try_recover_failed_tokens()
                available_tokens = self._get_available_tokens()

                if not available_tokens:
                    logger.warning("⚠️ 没有可用的token")
                    return None

            # 轮询选择token
            token = available_tokens[self._current_index % len(available_tokens)]
            self._current_index = (self._current_index + 1) % len(available_tokens)

            return token

    def _get_available_tokens(self) -> List[str]:
        """
        获取当前可用的认证用户token列表

        返回满足以下条件的token：
        1. is_available = True (可用状态)
        2. token_type == "user" (认证用户token)

        这确保轮询机制只会选择有效的认证用户token，跳过匿名用户token
        """
        available_user_tokens = [
            status.token for status in self.token_statuses.values()
            if status.is_available and status.token_type == "user"
        ]

        # 检查是否有匿名用户token并给出警告
        if not available_user_tokens and self.token_statuses:
            guest_tokens = [
                status.token for status in self.token_statuses.values()
                if status.token_type == "guest"
            ]
            if guest_tokens:
                logger.warning(f"⚠️ 检测到 {len(guest_tokens)} 个匿名用户token，轮询机制将跳过这些token")

        return available_user_tokens

    def _try_recover_failed_tokens(self):
        """尝试恢复失败的token"""
        current_time = time.time()
        recovered_count = 0

        for status in self.token_statuses.values():
            if (not status.is_available and
                current_time - status.last_failure_time > self.recovery_timeout):
                status.is_available = True
                status.failure_count = 0
                recovered_count += 1
                logger.info(f"🔄 恢复失败token: {status.token[:20]}...")

        if recovered_count > 0:
            logger.info(f"✅ 恢复了 {recovered_count} 个失败的token")

    def mark_token_success(self, token: str):
        """标记token使用成功"""
        with self._lock:
            if token in self.token_statuses:
                status = self.token_statuses[token]
                status.total_requests += 1
                status.successful_requests += 1
                status.last_success_time = time.time()
                status.failure_count = 0  # 重置失败计数

                if not status.is_available:
                    status.is_available = True
                    logger.info(f"✅ Token恢复可用: {token[:20]}...")

    def mark_token_failure(self, token: str, error: Exception = None):
        """标记token使用失败"""
        with self._lock:
            if token in self.token_statuses:
                status = self.token_statuses[token]
                status.total_requests += 1
                status.failure_count += 1
                status.last_failure_time = time.time()

                if status.failure_count >= self.failure_threshold:
                    status.is_available = False
                    logger.warning(f"🚫 Token已禁用: {token[:20]}... (失败 {status.failure_count} 次)")

    def get_pool_status(self) -> Dict:
        """获取token池状态信息"""
        with self._lock:
            available_count = len(self._get_available_tokens())
            total_count = len(self.token_statuses)

            # 统计健康token数量
            healthy_count = sum(1 for status in self.token_statuses.values() if status.is_healthy)

            status_info = {
                "total_tokens": total_count,
                "available_tokens": available_count,
                "unavailable_tokens": total_count - available_count,
                "healthy_tokens": healthy_count,
                "unhealthy_tokens": total_count - healthy_count,
                "current_index": self._current_index,
                "tokens": []
            }

            for token, status in self.token_statuses.items():
                status_info["tokens"].append({
                    "token": f"{token[:10]}...{token[-10:]}",
                    "token_type": status.token_type,
                    "is_available": status.is_available,
                    "failure_count": status.failure_count,
                    "success_count": status.successful_requests,
                    "success_rate": f"{status.success_rate:.2%}",
                    "total_requests": status.total_requests,
                    "is_healthy": status.is_healthy,
                    "last_failure_time": status.last_failure_time,
                    "last_success_time": status.last_success_time
                })

            return status_info

    def update_tokens(self, new_tokens: List[str]):
        """动态更新token列表"""
        with self._lock:
            # 保留现有token的状态信息
            old_statuses = self.token_statuses.copy()
            self.token_statuses.clear()

            original_count = len(new_tokens)
            unique_tokens = []

            # 去重并添加新token，保留已存在token的状态
            for token in new_tokens:
                if token and token not in self.token_statuses:  # 过滤空token和重复token
                    if token in old_statuses:
                        self.token_statuses[token] = old_statuses[token]
                    else:
                        # 预设为认证用户token，因为这些是用户手动配置的token
                        self.token_statuses[token] = TokenStatus(token=token, token_type="user")
                    unique_tokens.append(token)

            # 记录去重信息
            duplicate_count = original_count - len(unique_tokens)
            if duplicate_count > 0:
                logger.warning(f"⚠️ 更新时检测到 {duplicate_count} 个重复token，已自动去重")

            # 重置索引
            self._current_index = 0

            logger.info(f"🔄 更新Token池，共 {len(self.token_statuses)} 个token")

    async def health_check_token(self, token: str, auth_url: str = "https://chat.qwen.ai/api/v1/auths/") -> bool:
        """
        异步健康检查单个token

        使用Z.AI认证API验证token的有效性，通过检查响应内容判断token是否有效

        Args:
            token: 要检查的token
            auth_url: 认证URL

        Returns:
            token是否健康
        """
        try:
            # 构建完整的请求头，模拟真实浏览器请求
            headers = {
                "Accept": "*/*",
                "Accept-Language": "en-US;q=0.9",
                "Authorization": f"Bearer {token}",
                "Connection": "keep-alive",
                "Content-Type": "application/json",
                "DNT": "1",
                "Referer": "https://chat.qwen.ai/",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
                "sec-ch-ua": '"Chromium";v="140", "Not=A?Brand";v="24", "Google Chrome";v="140"',
                "sec-ch-ua-mobile": "?0",
                "sec-ch-ua-platform": "Windows"
            }

            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(auth_url, headers=headers)

                # 验证token有效性并获取类型
                token_type, is_healthy = self._validate_token_response(response)

                # 更新token类型
                if token in self.token_statuses:
                    self.token_statuses[token].token_type = token_type

                if is_healthy:
                    self.mark_token_success(token)
                else:
                    # 简化错误信息，只记录关键错误类型
                    if token_type == "guest":
                        error_msg = "匿名用户token"
                    elif response.status_code != 200:
                        error_msg = f"HTTP {response.status_code}"
                    else:
                        error_msg = "认证失败"

                    self.mark_token_failure(token, Exception(error_msg))

                return is_healthy

        except (httpx.TimeoutException, httpx.ConnectError, Exception) as e:
            self.mark_token_failure(token, e)
            return False

    def _validate_token_response(self, response: httpx.Response) -> bool:
        """
        基于QWEN API响应中的role字段验证token类型

        验证规则：
        - role: "user" = 认证用户token（有效，可用于AUTH_TOKENS）
        - role: "guest" = 匿名用户token（无效，不应在AUTH_TOKENS中）
        - 无role字段或其他值 = 无效token

        Args:
            response: HTTP响应对象

        Returns:
            token是否为有效的认证用户token
        """
        # 首先检查HTTP状态码
        if response.status_code != 200:
            return ("unknown", False)

        try:
            # 尝试解析JSON响应
            response_data = response.json()

            if not isinstance(response_data, dict):
                return ("unknown", False)

            # 检查是否包含错误信息
            if "error" in response_data:
                return ("unknown", False)

            if "message" in response_data and "error" in response_data.get("message", "").lower():
                return ("unknown", False)

            # 核心验证：检查role字段
            role = response_data.get("role")

            if role == "user":
                return ("user", True)
            elif role == "guest":

                if not hasattr(self, '_guest_token_warned'):
                    logger.warning("⚠️ 检测到匿名用户token，建议仅在AUTH_TOKENS中配置认证用户token")
                    self._guest_token_warned = True
                return ("guest", False)
            else:
                return ("unknown", False)

        except (ValueError, Exception):
            return ("unknown", False)

    async def health_check_all(self, auth_url: str = "https://chat.qwen.ai/api/v1/auths/"):
        """异步健康检查所有token"""
        if not self.token_statuses:
            logger.warning("⚠️ Token池为空，跳过健康检查")
            return

        total_tokens = len(self.token_statuses)
        logger.info(f"🔍 开始Token池健康检查... (共 {total_tokens} 个token)")

        # 并发执行所有token的健康检查
        tasks = []
        token_list = list(self.token_statuses.keys())

        for token in token_list:
            task = self.health_check_token(token, auth_url)
            tasks.append(task)

        # 执行并收集结果
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # 统计结果
        healthy_count = 0
        failed_count = 0
        exception_count = 0

        for i, result in enumerate(results):
            if result is True:
                healthy_count += 1
            elif result is False:
                failed_count += 1
            else:
                # 异常情况
                exception_count += 1
                token = token_list[i]
                logger.error(f"💥 Token {token[:20]}... 健康检查异常: {result}")

        health_rate = (healthy_count / total_tokens) * 100 if total_tokens > 0 else 0

        if healthy_count == 0 and total_tokens > 0:
            logger.warning(f"⚠️ 健康检查完成: 0/{total_tokens} 个token健康 - 请检查token配置")
        elif failed_count > 0:
            logger.warning(f"⚠️ 健康检查完成: {healthy_count}/{total_tokens} 个token健康 ({health_rate:.1f}%)")
        else:
            logger.info(f"✅ 健康检查完成: {healthy_count}/{total_tokens} 个token健康")

        if exception_count > 0:
            logger.error(f"💥 {exception_count} 个token检查异常")


# 全局token池实例
_token_pool: Optional[TokenPool] = None
_pool_lock = Lock()


def get_token_pool() -> Optional[TokenPool]:
    """获取全局token池实例"""
    return _token_pool


def initialize_token_pool(tokens: List[str], failure_threshold: int = 3, recovery_timeout: int = 1800) -> TokenPool:
    """初始化全局token池"""
    global _token_pool
    with _pool_lock:
        _token_pool = TokenPool(tokens, failure_threshold, recovery_timeout)
        return _token_pool


def update_token_pool(tokens: List[str]):
    """更新全局token池"""
    global _token_pool
    with _pool_lock:
        if _token_pool:
            _token_pool.update_tokens(tokens)
        else:
            _token_pool = TokenPool(tokens)
