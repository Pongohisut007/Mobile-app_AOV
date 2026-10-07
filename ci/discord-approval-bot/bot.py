"""Approve the existing Jenkins input gate using a Discord Gateway bot.

Runs on a computer that can reach Jenkins. It opens no inbound HTTP port.
"""

from __future__ import annotations

import asyncio
import base64
import hashlib
import json
import logging
import os
import re
import sqlite3
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import discord
from discord.ext import tasks
from dotenv import load_dotenv


HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
LOG = logging.getLogger("approval_bot")
STATE_PATH = HERE / ".state.sqlite3"


def required(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise SystemExit(f"Set {name} in {HERE / '.env'}")
    return value


BOT_TOKEN = required("DISCORD_BOT_TOKEN")
GUILD_ID = int(required("DISCORD_GUILD_ID"))
CHANNEL_ID = int(required("DISCORD_CHANNEL_ID"))
APPROVER_IDS = {
    int(value.strip()) for value in required("APPROVER_IDS").split(",")
    if value.strip()
}
JOB_URL = required("JENKINS_MAIN_JOB_URL").rstrip("/") + "/"
JENKINS_USER = required("JENKINS_USER")
JENKINS_API_TOKEN = required("JENKINS_API_TOKEN")
if urllib.parse.urlparse(JOB_URL).scheme not in ("http", "https"):
    raise SystemExit("JENKINS_MAIN_JOB_URL must start with http:// or https://")


def database() -> sqlite3.Connection:
    connection = sqlite3.connect(STATE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


with database() as db:
    db.execute("""
        CREATE TABLE IF NOT EXISTS gates (
            gate_key TEXT PRIMARY KEY,
            build_url TEXT NOT NULL,
            input_id TEXT NOT NULL,
            proceed_url TEXT NOT NULL,
            message_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending'
        )
    """)


def jenkins_request(method: str, url: str):
    credentials = f"{JENKINS_USER}:{JENKINS_API_TOKEN}".encode("utf-8")
    authorization = base64.b64encode(credentials).decode("ascii")
    request = urllib.request.Request(
        url,
        method=method,
        headers={"Authorization": f"Basic {authorization}"},
        data=b"" if method == "POST" else None,
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        if method == "GET":
            return json.load(response)
        return response.status


def pending_actions(build_url: str) -> list[dict]:
    result = jenkins_request(
        "GET", build_url.rstrip("/") + "/wfapi/pendingInputActions"
    )
    if not isinstance(result, list):
        raise ValueError("Jenkins pendingInputActions did not return a list")
    return result


def gate_key(build_url: str, input_id: str) -> str:
    return hashlib.sha256(f"{build_url}\n{input_id}".encode()).hexdigest()[:32]


def safe_proceed_url(build_url: str, input_id: str, proceed_url: str) -> str:
    """Accept only the proceed URL for this exact build and input."""
    base = urllib.parse.urlparse(build_url)
    target = urllib.parse.urlparse(
        urllib.parse.urljoin(build_url, proceed_url)
    )
    expected_path = (
        base.path.rstrip("/")
        + "/input/"
        + urllib.parse.quote(input_id, safe="")
        + "/proceedEmpty"
    )
    if (
        target.scheme != base.scheme
        or target.netloc != base.netloc
        or target.path != expected_path
        or target.query
        or target.fragment
    ):
        raise ValueError("Unexpected Jenkins proceed URL")
    return target.geturl()


class ApprovalView(discord.ui.View):
    def __init__(self, client: "ApprovalBot", key: str):
        super().__init__(timeout=None)
        self.client = client
        self.key = key
        button = discord.ui.Button(
            label="อนุมัติ Production",
            style=discord.ButtonStyle.success,
            custom_id=f"approve:{key}",
        )
        button.callback = self.approve
        self.add_item(button)

    async def approve(self, interaction: discord.Interaction):
        if (
            interaction.guild_id != GUILD_ID
            or interaction.channel_id != CHANNEL_ID
            or interaction.user.id not in APPROVER_IDS
        ):
            await interaction.response.send_message(
                "คุณไม่มีสิทธิ์อนุมัติ gate นี้", ephemeral=True
            )
            return

        await interaction.response.defer(ephemeral=True, thinking=True)
        async with self.client.lock_for(self.key):
            with database() as db:
                row = db.execute(
                    "SELECT * FROM gates WHERE gate_key = ?", (self.key,)
                ).fetchone()
            if row is None or row["status"] != "pending":
                await interaction.followup.send(
                    "gate นี้ถูกจัดการไปแล้ว", ephemeral=True
                )
                return
            if int(row["message_id"]) != interaction.message.id:
                await interaction.followup.send(
                    "ข้อความนี้ไม่ตรงกับ gate ที่บันทึกไว้", ephemeral=True
                )
                return

            try:
                actions = await asyncio.to_thread(pending_actions, row["build_url"])
                action = next(
                    (
                        item for item in actions
                        if item.get("id") == row["input_id"]
                        and item.get("proceedUrl") == row["proceed_url"]
                    ),
                    None,
                )
                if action is None:
                    with database() as db:
                        db.execute(
                            "UPDATE gates SET status = 'closed' WHERE gate_key = ?",
                            (self.key,),
                        )
                    await interaction.message.edit(view=None)
                    await interaction.followup.send(
                        "Jenkins ไม่ได้รอ gate นี้แล้ว", ephemeral=True
                    )
                    return

                url = safe_proceed_url(
                    row["build_url"], row["input_id"], row["proceed_url"]
                )
                await asyncio.to_thread(jenkins_request, "POST", url)
            except Exception:
                LOG.exception("Could not approve gate %s", self.key)
                await interaction.followup.send(
                    "อนุมัติไม่สำเร็จ ตรวจ log ของ Bot แล้วลองอีกครั้ง",
                    ephemeral=True,
                )
                return

            with database() as db:
                db.execute(
                    "UPDATE gates SET status = 'approved' WHERE gate_key = ?",
                    (self.key,),
                )
            try:
                await interaction.message.edit(
                    content=(
                        interaction.message.content
                        + f"\n\n✅ อนุมัติโดย Discord user ID `{interaction.user.id}`"
                    ),
                    view=None,
                )
            except discord.HTTPException:
                LOG.exception("Jenkins approved but Discord message edit failed")
            await interaction.followup.send("อนุมัติใน Jenkins แล้ว", ephemeral=True)


class ApprovalBot(discord.Client):
    def __init__(self):
        super().__init__(intents=discord.Intents.default())
        self.locks: dict[str, asyncio.Lock] = {}

    def lock_for(self, key: str) -> asyncio.Lock:
        return self.locks.setdefault(key, asyncio.Lock())

    async def setup_hook(self):
        with database() as db:
            rows = db.execute(
                "SELECT gate_key, message_id FROM gates WHERE status = 'pending'"
            ).fetchall()
        for row in rows:
            self.add_view(
                ApprovalView(self, row["gate_key"]),
                message_id=int(row["message_id"]),
            )
        self.poll_jenkins.start()

    async def on_ready(self):
        LOG.info("Logged in as %s; watching %s", self.user, JOB_URL)

    @tasks.loop(seconds=10)
    async def poll_jenkins(self):
        try:
            build = await asyncio.to_thread(
                jenkins_request,
                "GET",
                JOB_URL + "lastBuild/api/json?tree=url,number,building",
            )
            if not build.get("building"):
                return
            build_url = build["url"]
            actions = await asyncio.to_thread(pending_actions, build_url)
            channel = self.get_channel(CHANNEL_ID)
            if channel is None:
                channel = await self.fetch_channel(CHANNEL_ID)

            for action in actions:
                if "Deploy to production?" not in action.get("message", ""):
                    continue
                input_id = action.get("id")
                proceed_url = action.get("proceedUrl")
                if not input_id or not proceed_url:
                    continue
                safe_proceed_url(build_url, input_id, proceed_url)
                key = gate_key(build_url, input_id)
                with database() as db:
                    exists = db.execute(
                        "SELECT 1 FROM gates WHERE gate_key = ?", (key,)
                    ).fetchone()
                if exists:
                    continue

                details = discord.utils.escape_mentions(action["message"])
                content = (
                    "🟡 **Production Approval Required**\n"
                    + details[:1400]
                    + "\n"
                    + build_url
                )
                view = ApprovalView(self, key)
                message = await channel.send(
                    content,
                    view=view,
                    allowed_mentions=discord.AllowedMentions.none(),
                )
                with database() as db:
                    db.execute(
                        """INSERT INTO gates
                           (gate_key, build_url, input_id, proceed_url, message_id)
                           VALUES (?, ?, ?, ?, ?)""",
                        (key, build_url, input_id, proceed_url, str(message.id)),
                    )
                LOG.info("Sent approval message for %s input %s", build_url, input_id)
        except urllib.error.HTTPError as error:
            LOG.warning("Jenkins returned HTTP %s", error.code)
        except Exception:
            LOG.exception("Failed to poll Jenkins")

    @poll_jenkins.before_loop
    async def before_poll(self):
        await self.wait_until_ready()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    ApprovalBot().run(BOT_TOKEN, log_handler=None)
