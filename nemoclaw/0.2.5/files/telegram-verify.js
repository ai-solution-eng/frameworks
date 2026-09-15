// One-off Telegram channel verification (runs once per pod start, BEFORE the
// gateway starts, so it can call getUpdates without competing with the
// gateway's own long-poll).
//
// Steps:
//   1) getMe        -> proves the bot token is valid AND outbound egress to
//                      api.telegram.org works. (This alone proves the channel
//                      is "functioning" at the transport/auth level.)
//   2) getUpdates   -> (bounded poll) finds the most recent chat the bot has
//                      seen (a user who sent /start, or a group).
//   3) sendMessage  -> sends ONE test message to that chat, proving real
//                      end-to-end delivery.
//
// If no chat has messaged the bot yet, the poll times out and the script logs a
// clear note and exits 0 (non-fatal): the channel is connected (getMe ok) but
// there is simply no target to send to yet. The next pod restart retries.
//
// Reads TELEGRAM_BOT_TOKEN / TELEGRAM_TEST_CHAT_ID / TELEGRAM_TEST_MESSAGE /
// TELEGRAM_VERIFY_TIMEOUT (seconds, default 45) from the environment.

const TOKEN = (process.env.TELEGRAM_BOT_TOKEN || "").trim();
const TEST_CHAT_ID = (process.env.TELEGRAM_TEST_CHAT_ID || "").trim();
const TEST_MESSAGE =
  process.env.TELEGRAM_TEST_MESSAGE ||
  "NemoClaw Telegram channel is online (one-off validation)";
const TIMEOUT_S = parseInt(process.env.TELEGRAM_VERIFY_TIMEOUT || "20", 10);
const API = "https://api.telegram.org/bot" + TOKEN;

const log = (m) => console.log("[telegram-verify] " + m);

async function getJSON(path) {
  const r = await fetch(API + path);
  return r.json();
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function findChatId() {
  // An explicit chat id short-circuits the poll.
  if (TEST_CHAT_ID) return TEST_CHAT_ID;
  const deadline = Date.now() + TIMEOUT_S * 1000;
  while (Date.now() < deadline) {
    try {
      const d = await getJSON("/getUpdates?limit=5");
      for (const u of d.result || []) {
        const m = u && (u.message || u.edited_message || u.channel_post);
        if (m && m.chat && m.chat.id) return String(m.chat.id);
      }
    } catch (e) {
      log("getUpdates error (retrying): " + e.message);
    }
    await sleep(5000);
  }
  return null;
}

async function main() {
  if (!TOKEN || TOKEN === "CHANGE_ME-telegram-bot-token") {
    log("skipped: no bot token set (telegram disabled or placeholder)");
    return;
  }

  // 1) getMe: token validity + egress.
  let me;
  try {
    me = await getJSON("/getMe");
  } catch (e) {
    log("getMe FAILED (egress blocked or network error?): " + e.message);
    return; // non-fatal
  }
  if (!me.ok) {
    log("getMe failed: " + (me.description || JSON.stringify(me)));
    return;
  }
  log("token valid: bot @@" + me.result.username + " (id " + me.result.id + ")");

  // 2) find a chat id (explicit, else bounded poll of getUpdates).
  log("polling for a chat to send the test message (timeout " + TIMEOUT_S + "s)...");
  const chatId = await findChatId();
  if (!chatId) {
    log(
      "channel CONNECTED (getMe ok) but no chat has messaged the bot yet. " +
        "Send /start to @@" + me.result.username +
        " and the test message will be sent on the next restart. (non-fatal)"
    );
    return;
  }

  // 3) ONE-OFF test message: real end-to-end delivery.
  const params = new URLSearchParams({ chat_id: chatId, text: TEST_MESSAGE });
  let send;
  try {
    send = await getJSON("/sendMessage?" + params.toString());
  } catch (e) {
    log("sendMessage FAILED: " + e.message);
    return;
  }
  if (send.ok) {
    log(
      "SUCCESS: one-off test message delivered to chat " +
        chatId + " (message_id " + send.result.message_id + ")"
    );
  } else {
    log("sendMessage failed: " + (send.description || JSON.stringify(send)));
  }
}

main().catch((e) => log("error: " + e.message));
