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
import sys
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


def check_jenkins() -> None:
    """Print safe API diagnostics without displaying either credential."""
    root_url = JOB_URL.split("/job/", 1)[0].rstrip("/") + "/"
    checks = (
        ("identity", root_url + "whoAmI/api/json"),
        ("main job", JOB_URL + "api/json?tree=fullName"),
        ("last build", JOB_URL + "lastBuild/api/json?tree=number,building"),
        ("pending input", JOB_URL + "lastBuild/wfapi/pendingInputActions"),
    )
    for label, url in checks:
        try:
            result = jenkins_request("GET", url)
            if label == "identity":
                extra = f"authenticated={result.get('authenticated')}"
            elif label == "last build":
                extra = f"number={result.get('number')} building={result.get('building')}"
            elif label == "pending input":
                extra = f"count={len(result)}" if isinstance(result, list) else "unexpected response"
            else:
                extra = ""
            print(f"{label}: HTTP 200 {extra}".rstrip())
        except urllib.error.HTTPError as error:
            authenticated_as = error.headers.get("X-You-Are-Authenticated-As", "unknown")
            permission = error.headers.get("X-Required-Permission", "not supplied")
            from_jenkins = "yes" if error.headers.get("X-Jenkins") else "no/unknown"
            print(
                f"{label}: HTTP {error.code}; "
                f"authenticated-as={authenticated_as}; "
                f"required-permission={permission}; "
                f"X-Jenkins={from_jenkins}"
            )
        except Exception as error:
            print(f"{label}: {type(error).__name__}: {error}")

    try:
        build = jenkins_request(
            "GET", JOB_URL + "lastBuild/api/json?tree=number"
        )
        number = build["number"]
        actions = pending_actions(f"{JOB_URL}{number}/")
        print(f"numeric build #{number} pending input: HTTP 200 count={len(actions)}")
    except urllib.error.HTTPError as error:
        print(f"numeric build pending input: HTTP {error.code}")
    except Exception as error:
        print(f"numeric build pending input: {type(error).__name__}: {error}")


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
    """Validate Jenkins's action URL, then use the no-parameter input endpoint."""
    base = urllib.parse.urlparse(build_url)
    target = urllib.parse.urlparse(
        urllib.parse.urljoin(build_url, proceed_url)
    )
    empty_path = (
        base.path.rstrip("/")
        + "/input/"
        + urllib.parse.quote(input_id, safe="")
        + "/proceedEmpty"
    )
    submit_path = base.path.rstrip("/") + "/wfapi/inputSubmit"
    valid_action = (
        (target.path == empty_path and not target.query)
        or (
            target.path == submit_path
            and urllib.parse.parse_qs(target.query, strict_parsing=True)
            == {"inputId": [input_id]}
        )
    )
    if (
        target.scheme != base.scheme
        or target.netloc != base.netloc
        or not valid_action
        or target.fragment
    ):
        raise ValueError("Unexpected Jenkins proceed URL")
    return urllib.parse.urlunparse(base._replace(path=empty_path, query="", fragment=""))


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
        if self.get_guild(GUILD_ID) is None:
            LOG.error(
                "Bot is not installed in the configured Discord server; "
                "run --check-discord after inviting it"
            )
            await self.close()
            return
        try:
            channel = await self.fetch_channel(CHANNEL_ID)
            if getattr(getattr(channel, "guild", None), "id", None) != GUILD_ID:
                raise ValueError("Configured channel is not in configured server")
        except (discord.Forbidden, discord.NotFound, ValueError):
            LOG.error(
                "Bot cannot access the configured Discord channel; "
                "check channel ID and View Channel permission"
            )
            await self.close()
            return
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
            number = build.get("number")
            if not isinstance(number, int) or number < 1:
                raise ValueError("Jenkins returned an invalid lastBuild number")
            # The Jenkins root URL in its API may differ from the reachable
            # address configured on this computer (for example jenkins.local).
            build_url = f"{JOB_URL}{number}/"
            actions = await asyncio.to_thread(pending_actions, build_url)

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
                channel = self.get_channel(CHANNEL_ID)
                if channel is None:
                    channel = await self.fetch_channel(CHANNEL_ID)
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
            path = urllib.parse.urlparse(error.url).path
            LOG.warning(
                "Jenkins GET %s returned HTTP %s "
                "(authenticated-as=%s, required-permission=%s)",
                path,
                error.code,
                error.headers.get("X-You-Are-Authenticated-As", "unknown"),
                error.headers.get("X-Required-Permission", "not supplied"),
            )
        except Exception:
            LOG.exception("Failed to poll Jenkins")

    @poll_jenkins.before_loop
    async def before_poll(self):
        await self.wait_until_ready()


class DiscordDiagnostic(discord.Client):
    def __init__(self):
        super().__init__(intents=discord.Intents.default())

    async def on_ready(self):
        print(f"bot application ID: {self.application_id}")
        print(f"server IDs containing bot: {[guild.id for guild in self.guilds]}")
        print(f"bot is in configured server: {self.get_guild(GUILD_ID) is not None}")
        try:
            channel = await self.fetch_channel(CHANNEL_ID)
            print("configured channel: accessible")
            channel_guild = getattr(channel, "guild", None)
            print(f"channel belongs to configured server: {getattr(channel_guild, 'id', None) == GUILD_ID}")
        except discord.Forbidden as error:
            print(f"configured channel: HTTP {error.status} Missing Access")
        except discord.NotFound as error:
            print(f"configured channel: HTTP {error.status} Not Found")
        await self.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    if sys.argv[1:] == ["--check-jenkins"]:
        check_jenkins()
    elif sys.argv[1:] == ["--check-discord"]:
        DiscordDiagnostic().run(BOT_TOKEN, log_handler=None)
    else:
        ApprovalBot().run(BOT_TOKEN, log_handler=None)
