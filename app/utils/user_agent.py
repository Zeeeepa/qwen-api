#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
用户代理工具模块
提供动态随机用户代理生成功能
"""

import random
from typing import Dict, Optional
from fake_useragent import UserAgent

# 全局 UserAgent 实例（单例模式）
_user_agent_instance: Optional[UserAgent] = None


def get_user_agent_instance() -> UserAgent:
    """获取或创建 UserAgent 实例（单例模式）"""
    global _user_agent_instance
    if _user_agent_instance is None:
        _user_agent_instance = UserAgent()
    return _user_agent_instance


def get_random_user_agent(browser_type: Optional[str] = None) -> str:
    """
    获取随机用户代理字符串

    Args:
        browser_type: 指定浏览器类型 ('chrome', 'firefox', 'safari', 'edge')
                     如果为 None，则随机选择

    Returns:
        str: 用户代理字符串
    """
    ua = get_user_agent_instance()

    # 如果没有指定浏览器类型，随机选择一个（偏向 Chrome 和 Edge）
    if browser_type is None:
        browser_choices = ["chrome", "chrome", "chrome", "edge", "edge", "firefox", "safari"]
        browser_type = random.choice(browser_choices)

    # 根据浏览器类型获取用户代理
    if browser_type == "chrome":
        user_agent = ua.chrome
    elif browser_type == "edge":
        user_agent = ua.edge
    elif browser_type == "firefox":
        user_agent = ua.firefox
    elif browser_type == "safari":
        user_agent = ua.safari
    else:
        user_agent = ua.random

    return user_agent


# 通用 UserAgent headers 生成函数
def get_dynamic_headers(
    referer: Optional[str] = None,
    origin: Optional[str] = None,
    browser_type: Optional[str] = None,
    additional_headers: Optional[Dict[str, str]] = None
) -> Dict[str, str]:
    """
    生成动态浏览器 headers，包含随机 User-Agent

    Args:
        referer: 引用页面 URL
        origin: 源站 URL
        browser_type: 指定浏览器类型
        additional_headers: 额外的 headers

    Returns:
        Dict[str, str]: 包含动态 User-Agent 的 headers
    """
    user_agent = get_random_user_agent(browser_type)

    # 基础 headers
    headers = {
        "User-Agent": user_agent,
        "Accept": "application/json, text/event-stream",
        "Accept-Language": "en-US;q=0.9,en;q=0.8",
        "Accept-Encoding": "gzip, deflate, br",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
        "Pragma": "no-cache",
    }

    # 添加可选的 headers
    if referer:
        headers["Referer"] = referer

    if origin:
        headers["Origin"] = origin

    # 根据用户代理添加浏览器特定的 headers
    if "Chrome/" in user_agent or "Edg/" in user_agent:
        # Chrome/Edge 特定的 headers
        chrome_version = "139"
        edge_version = "139"

        try:
            if "Chrome/" in user_agent:
                chrome_version = user_agent.split("Chrome/")[1].split(".")[0]
        except:
            pass

        try:
            if "Edg/" in user_agent:
                edge_version = user_agent.split("Edg/")[1].split(".")[0]
                sec_ch_ua = f'"Microsoft Edge";v="{edge_version}", "Chromium";v="{chrome_version}", "Not_A Brand";v="24"'
            else:
                sec_ch_ua = f'"Not_A Brand";v="8", "Chromium";v="{chrome_version}", "Google Chrome";v="{chrome_version}"'
        except:
            sec_ch_ua = f'"Not_A Brand";v="8", "Chromium";v="{chrome_version}", "Google Chrome";v="{chrome_version}"'

        headers.update({
            "sec-ch-ua": sec_ch_ua,
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Windows"',
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
        })

    # 添加额外的 headers
    if additional_headers:
        headers.update(additional_headers)

    return headers


