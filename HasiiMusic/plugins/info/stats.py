# ==============================================================================
# stats.py - Bot Statistics Command (Sudo Only)
# ==============================================================================
# This plugin shows comprehensive bot statistics and system information.
#
# Commands:
# - /stats - Show detailed bot statistics
#
# Displays:
# - Total users and groups using the bot
# - System info (OS, Python version, Pyrogram version)
# - Bot uptime
# - Memory and CPU usage
# - Number of loaded plugins
#
# Only sudo users can use this command.
# ==============================================================================

# Copyright (c) 2025 Hasindu Nagolla
# Licensed under the MIT License.
# This file is part of ˹ʜᴀꜱɪɪ ᴍᴜꜱɪᴄ˼


import os
import platform
import sys

import psutil
import aiohttp
from pyrogram import __version__, filters, types
from pytgcalls import __version__ as pytgver

from HasiiMusic import app, config, db, lang, userbot
from HasiiMusic.plugins import all_modules


@app.on_message(filters.command(["stats"]) & ~app.bl_users)
@lang.language()
async def _stats(_, m: types.Message):
    # Auto-delete command message
    try:
        await m.delete()
    except Exception:
        pass
    
    # Check if user is sudo
    if m.from_user.id not in app.sudoers:
        return
    
    sent = await m.reply_photo(
        photo=config.PING_IMG,
        caption=m.lang["stats_fetching"],
    )

    pid = os.getpid()
    cpu_percent = psutil.cpu_percent(interval=0.5)
    cpu_count = psutil.cpu_count()
    
    # Get memory info
    mem = psutil.virtual_memory()
    used_mem = round(mem.used / (1024 ** 3), 2)  # Convert to GB
    total_mem = round(mem.total / (1024 ** 3), 2)
    
    # Get disk info
    disk = psutil.disk_usage("/")
    used_disk = round(disk.used / (1024 ** 3), 2)  # Convert to GB
    total_disk = round(disk.total / (1024 ** 3), 2)
    
    # Fetch database stats from Ballerina Microservice
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("http://localhost:9090/db_stats") as resp:
                if resp.status == 200:
                    db_stats = await resp.json()
                else:
                    print(f"Ballerina API Error: {resp.status}")
                    db_stats = {}
    except Exception as e:
        print(f"Error connecting to Ballerina API: {e}")
        db_stats = {}

    # Fallback to 0 if Ballerina API is down or missing fields
    if not db_stats:
        db_stats = {
            "blocked_chats": 0,
            "blocked_users": 0,
            "sudo_users": 0,
            "served_chats": 0,
            "served_users": 0
        }
        
    _utext = m.lang["stats_user"].format(
        app.name,
        len(userbot.clients),
        config.AUTO_LEAVE,
        db_stats.get("blocked_chats", 0),
        db_stats.get("blocked_users", 0),
        db_stats.get("sudo_users", 0),
        db_stats.get("served_chats", 0),
        db_stats.get("served_users", 0),
    )
    
    # Add system stats for sudo users
    _utext += m.lang["stats_sudo"].format(
        len(all_modules),
        platform.system(),
        f"{used_mem}GB | {total_mem}GB",
        f"{cpu_percent}% ({cpu_count} cores)",
        f"{used_disk}GB | {total_disk}GB",
        sys.version.split()[0],
        __version__,
        pytgver,
    )
    
    await sent.edit_caption(_utext)
