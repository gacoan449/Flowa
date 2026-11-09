const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

async function sendToUser(userId, title, body, data) {
  const devices = await db.collection("users").doc(userId).collection("devices").get();
  const tokens = devices.docs.map((doc) => doc.id).filter(Boolean);
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    android: {
      priority: "high",
      notification: { channelId: "flowa_messages", sound: "default" },
    },
  });

  const stale = [];
  response.responses.forEach((result, index) => {
    if (!result.success && (
      result.error?.code === "messaging/registration-token-not-registered" ||
      result.error?.code === "messaging/invalid-registration-token"
    )) stale.push(tokens[index]);
  });
  await Promise.all(stale.map((token) =>
    db.collection("users").doc(userId).collection("devices").doc(token).delete()
  ));
}

exports.notifyChatMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message || !message.senderId) return;
    const chatId = event.params.chatId;
    const chatSnap = await db.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data();
    if ((chat.blockedBy || []).length > 0) return;

    const recipientId = (chat.participants || []).find((id) => id !== message.senderId);
    if (!recipientId) return;
    const senderProfile = await db.collection("public_profiles").doc(message.senderId).get();
    const senderName = senderProfile.data()?.displayName || "Pengguna Flowa";
    const body = message.type === "image" ? "Mengirim foto" :
      message.type === "audio" ? "Mengirim pesan suara" :
      (message.text || "Pesan baru").slice(0, 120);

    await sendToUser(recipientId, senderName, body, {
      type: "chat_message", chatId, senderId: message.senderId,
    });
    logger.info("Chat notification dispatched", { chatId, recipientId });
  }
);

exports.notifySupportMessage = onDocumentCreated(
  "support_threads/{threadId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message || !message.senderId) return;
    const threadSnap = await db.collection("support_threads").doc(event.params.threadId).get();
    if (!threadSnap.exists) return;
    const thread = threadSnap.data();
    if (thread.userId === message.senderId) {
      const admins = await db.collection("users").where("role", "==", "admin").get();
      await Promise.all(admins.docs.map((doc) =>
        sendToUser(doc.id, "Customer Service Flowa", (message.text || "Pesan bantuan baru").slice(0, 120), {
          type: "support_message", threadId: event.params.threadId,
        })
      ));
    } else if (thread.userId) {
      await sendToUser(thread.userId, "Customer Service Flowa",
        (message.text || "Balasan baru dari Customer Service").slice(0, 120), {
          type: "support_message", threadId: event.params.threadId,
        });
    }
    logger.info("Support notification dispatched", { threadId: event.params.threadId });
  }
);
