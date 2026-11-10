const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

async function sendToUser(userId, title, body, data) {
  const platform = await db.collection("app_config").doc("platform").get();
  if (platform.data()?.pushNotificationsEnabled === false) return;
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
  return response.successCount > 0;
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

    const delivered = await sendToUser(recipientId, senderName, body, {
      type: "chat_message", chatId, senderId: message.senderId,
    });
    if (delivered) {
      await event.data.ref.update({ deliveredTo: admin.firestore.FieldValue.arrayUnion(recipientId) });
    }
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

const { onCall, HttpsError } = require("firebase-functions/v2/https");

const OWNER_EMAIL = "flowa324@gmail.com";
const ROLE_PERMISSIONS = {
  admin: ["dashboard", "content", "marketplace", "orders", "users", "security", "system"],
  moderator: ["dashboard", "content", "marketplace", "reports"],
  support: ["dashboard", "chat", "orders", "disputes", "users_read"],
  customer: [],
};

function requireSignedIn(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan login terlebih dahulu.");
  return request.auth;
}
function requireOwner(request) {
  const auth = requireSignedIn(request);
  if ((auth.token.email || "").toLowerCase() !== OWNER_EMAIL) {
    throw new HttpsError("permission-denied", "Hanya pemilik Flowa yang dapat mengelola role.");
  }
  return auth;
}
function hasPermission(auth, permission) {
  return auth.token.email?.toLowerCase() === OWNER_EMAIL ||
    auth.token.role === "admin" ||
    (Array.isArray(auth.token.permissions) && auth.token.permissions.includes(permission));
}

exports.setStaffRole = onCall(async (request) => {
  const owner = requireOwner(request);
  const { uid, role } = request.data || {};
  if (typeof uid !== "string" || !uid || !Object.prototype.hasOwnProperty.call(ROLE_PERMISSIONS, role) || role === "customer") {
    throw new HttpsError("invalid-argument", "UID atau role tidak valid.");
  }
  const userRecord = await admin.auth().getUser(uid);
  if ((userRecord.email || "").toLowerCase() === OWNER_EMAIL) {
    throw new HttpsError("failed-precondition", "Role pemilik utama tidak dapat diubah.");
  }
  const permissions = ROLE_PERMISSIONS[role];
  await admin.auth().setCustomUserClaims(uid, { role, admin: role === "admin", permissions });
  await db.collection("users").doc(uid).set({
    role, permissions, roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    roleUpdatedBy: owner.uid,
  }, { merge: true });
  await db.collection("admin_audit_logs").add({
    actorUid: owner.uid, targetUid: uid, action: "staff_role_updated",
    role, permissions, createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true, role, permissions };
});

exports.createMarketplaceOrder = onCall(async (request) => {
  const auth = requireSignedIn(request);
  const { productId, quantity, paymentMethod, deliveryMethod, deliveryAddress, note } = request.data || {};
  if (typeof productId !== "string" || !productId ||
      !Number.isInteger(quantity) || quantity < 1 || quantity > 99 ||
      !["cod", "wallet"].includes(paymentMethod) ||
      !["delivery", "meetup"].includes(deliveryMethod) ||
      (deliveryMethod === "delivery" && (typeof deliveryAddress !== "string" || deliveryAddress.trim().length < 8))) {
    throw new HttpsError("invalid-argument", "Detail pesanan tidak valid.");
  }
  const settingsSnap = await db.collection("app_config").doc("platform").get();
  const settings = settingsSnap.data() || {};
  if (settings.maintenanceMode === true) throw new HttpsError("failed-precondition", "Flowa sedang dalam pemeliharaan.");
  if (settings.ordersEnabled === false) throw new HttpsError("failed-precondition", "Penerimaan pesanan sedang dinonaktifkan.");
  if (paymentMethod === "cod" && settings.codEnabled === false) throw new HttpsError("failed-precondition", "COD sedang dinonaktifkan.");
  if (paymentMethod === "wallet" && settings.walletEnabled !== true) throw new HttpsError("failed-precondition", "Pembayaran saldo belum diaktifkan oleh admin.");

  const productRef = db.collection("products").doc(productId);
  const orderRef = db.collection("orders").doc();
  const walletRef = db.collection("wallets").doc(auth.uid);
  const result = await db.runTransaction(async (tx) => {
    const productSnap = await tx.get(productRef);
    if (!productSnap.exists) throw new HttpsError("not-found", "Produk tidak ditemukan.");
    const product = productSnap.data();
    if (product.status !== "active") throw new HttpsError("failed-precondition", "Produk tidak tersedia.");
    if (product.sellerId === auth.uid) throw new HttpsError("failed-precondition", "Kamu tidak dapat membeli produk sendiri.");
    if (deliveryMethod === "delivery" && !(product.deliveryOptions || []).includes("delivery")) {
      throw new HttpsError("failed-precondition", "Penjual tidak menyediakan pengiriman.");
    }
    if (deliveryMethod === "meetup" && !(product.deliveryOptions || []).includes("meetup")) {
      throw new HttpsError("failed-precondition", "Penjual tidak menyediakan COD/temu langsung.");
    }
    const stock = Number(product.stock || 0);
    if (stock < quantity) throw new HttpsError("failed-precondition", "Stok produk tidak mencukupi.");
    const unitPrice = Number(product.price);
    if (!Number.isSafeInteger(unitPrice) || unitPrice <= 0) throw new HttpsError("failed-precondition", "Harga produk tidak valid.");
    const subtotal = unitPrice * quantity;
    const feePercent = Number(settings.serviceFeePercent || 0);
    const minimumFee = Number(settings.minimumServiceFee || 0);
    if (!Number.isFinite(feePercent) || feePercent < 0 || feePercent > 100 ||
        !Number.isSafeInteger(minimumFee) || minimumFee < 0) {
      throw new HttpsError("failed-precondition", "Konfigurasi biaya layanan tidak valid. Hubungi admin.");
    }
    const serviceFee = Math.max(minimumFee, Math.floor(subtotal * feePercent / 100));
    const total = subtotal + serviceFee;
    if (paymentMethod === "wallet") {
      const walletSnap = await tx.get(walletRef);
      const balance = Number(walletSnap.data()?.balance || 0);
      if (balance < total) throw new HttpsError("failed-precondition", "Saldo Flowa tidak mencukupi.");
      tx.set(walletRef, { balance: balance - total, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      const ledgerRef = db.collection("wallet_transactions").doc();
      tx.set(ledgerRef, {
        uid: auth.uid, type: "purchase_debit", amount: total, orderId: orderRef.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    const nextStock = stock - quantity;
    tx.update(productRef, {
      stock: nextStock,
      status: nextStock === 0 ? "sold_out" : "active",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(orderRef, {
      orderId: orderRef.id, buyerId: auth.uid, sellerId: product.sellerId,
      productId, productTitle: product.title || "Produk",
      productImage: product.imageUrl || "", quantity, unitPrice, subtotal,
      serviceFee, total, paymentMethod, deliveryMethod,
      deliveryAddress: typeof deliveryAddress === "string" ? deliveryAddress.trim().slice(0, 500) : "",
      note: typeof note === "string" ? note.slice(0, 500) : "",
      status: paymentMethod === "wallet" ? "paid" : "awaiting_confirmation",
      paymentStatus: paymentMethod === "wallet" ? "paid" : "pay_on_delivery",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      statusHistory: [{ status: paymentMethod === "wallet" ? "paid" : "awaiting_confirmation", by: auth.uid, at: new Date().toISOString() }],
    });
    return { orderId: orderRef.id, total, status: paymentMethod === "wallet" ? "paid" : "awaiting_confirmation" };
  });
  logger.info("Marketplace order created", { orderId: result.orderId, buyerId: auth.uid });
  return result;
});

exports.updateMarketplaceOrderStatus = onCall(async (request) => {
  const auth = requireSignedIn(request);
  const { orderId, status, reason } = request.data || {};
  const allowed = ["confirmed", "processing", "shipped", "completed", "cancelled", "return_requested", "returned", "disputed"];
  if (typeof orderId !== "string" || !allowed.includes(status)) {
    throw new HttpsError("invalid-argument", "Pesanan atau status tidak valid.");
  }
  const ref = db.collection("orders").doc(orderId);
  const settingsSnap = await db.collection("app_config").doc("platform").get();
  const settings = settingsSnap.data() || {};
  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Pesanan tidak ditemukan.");
    const order = snap.data();
    const isBuyer = order.buyerId === auth.uid;
    const isSeller = order.sellerId === auth.uid;
    const privileged = hasPermission(auth, "orders") || hasPermission(auth, "disputes");
    const current = order.status;
    const createdAt = order.createdAt?.toDate ? order.createdAt.toDate().getTime() : 0;
    const cancelWindowMs = Math.max(0, Number(settings.cancellationWindowMinutes ?? 30)) * 60 * 1000;
    const insideCancelWindow = createdAt > 0 && Date.now() - createdAt <= cancelWindowMs;
    const buyerCancel = status === "cancelled" && isBuyer &&
      settings.allowBuyerCancellation !== false && insideCancelWindow &&
      ["awaiting_confirmation", "paid", "confirmed"].includes(current);
    const sellerAction = isSeller && (
      (status === "confirmed" && ["awaiting_confirmation", "paid"].includes(current)) ||
      (status === "processing" && current === "confirmed") ||
      (status === "shipped" && current === "processing") ||
      (status === "completed" && current === "shipped")
    );
    const caseReason = typeof reason === "string" ? reason.trim().slice(0, 1000) : "";
    const buyerRequest = isBuyer && caseReason.length >= 10 && (
      (status === "return_requested" && settings.returnsEnabled === true && current === "completed") ||
      (status === "disputed" && settings.disputesEnabled === true && ["completed", "shipped", "processing"].includes(current))
    );
    const adminAction = privileged && (
      status === "cancelled" || status === "returned" || status === "disputed" ||
      status === "completed" || status === "processing" || status === "shipped" || status === "confirmed"
    );
    if (!(buyerCancel || sellerAction || buyerRequest || adminAction)) {
      throw new HttpsError("permission-denied", "Akun tidak diizinkan mengubah status pesanan ini.");
    }
    if (status === "cancelled" && ["shipped", "completed", "returned"].includes(current)) {
      throw new HttpsError("failed-precondition", "Pesanan yang sudah dikirim tidak dapat dibatalkan dengan alur ini.");
    }
    let productSnap = null;
    let walletSnap = null;
    const restoreStock = status === "cancelled" && order.stockRestored !== true;
    const refundWallet = ["cancelled", "returned"].includes(status) && order.paymentMethod === "wallet" && order.paymentStatus === "paid" && order.refundProcessed !== true;
    const productRef = db.collection("products").doc(order.productId);
    const walletRef = db.collection("wallets").doc(order.buyerId);
    if (restoreStock) productSnap = await tx.get(productRef);
    if (refundWallet) walletSnap = await tx.get(walletRef);

    if (restoreStock && productSnap && productSnap.exists) {
      const data = productSnap.data();
      tx.update(productRef, { stock: Number(data.stock || 0) + Number(order.quantity || 1), status: "active", updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    }
    if (refundWallet) {
      const balance = Number(walletSnap?.data()?.balance || 0);
      tx.set(walletRef, { balance: balance + Number(order.total || 0), updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      const refundRef = db.collection("wallet_transactions").doc();
      tx.set(refundRef, {
        uid: order.buyerId, type: "purchase_refund", amount: Number(order.total || 0),
        orderId, createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    const history = Array.isArray(order.statusHistory) ? order.statusHistory : [];
    const now = admin.firestore.FieldValue.serverTimestamp();
    const caseRef = db.collection("order_cases").doc(orderId);
    if (status === "return_requested" || status === "disputed") {
      tx.set(caseRef, {
        orderId, buyerId: order.buyerId, sellerId: order.sellerId,
        type: status === "return_requested" ? "return" : "dispute",
        status: "open", reason: caseReason,
        openedBy: auth.uid, openedAt: now, updatedAt: now,
      }, { merge: true });
    }
    if (status === "returned" || (status === "completed" && current === "disputed")) {
      tx.set(caseRef, {
        status: status === "returned" ? "approved_return" : "resolved",
        resolution: status === "returned" ? "refund_or_return" : "completed",
        resolutionNote: typeof reason === "string" ? reason.slice(0, 1000) : "",
        resolvedBy: auth.uid, resolvedAt: now, updatedAt: now,
      }, { merge: true });
    }
    tx.update(ref, {
      status, statusReason: typeof reason === "string" ? reason.slice(0, 1000) : "",
      updatedAt: now,
      statusHistory: [...history, { status, by: auth.uid, at: new Date().toISOString(), reason: typeof reason === "string" ? reason.slice(0, 500) : "" }],
      ...(restoreStock ? { stockRestored: true } : {}),
      ...(refundWallet ? { refundProcessed: true, paymentStatus: "refunded" } : {}),
      ...(status === "returned" && order.paymentMethod === "cod" ? { refundStatus: "manual_review_required" } : {}),
      ...(status === "cancelled" && order.paymentMethod === "cod" ? { paymentStatus: "cancelled" } : {}),
      ...(status === "completed" && order.paymentMethod === "cod" ? { paymentStatus: "collected" } : {}),
    });
    return { orderId, previousStatus: current, status };
  });
  logger.info("Marketplace order status updated", { ...outcome, actorUid: auth.uid });
  return outcome;
});

exports.logClientFailure = onCall(async (request) => {
  const auth = requireSignedIn(request);
  const { message, stack, source } = request.data || {};
  if (typeof message !== "string" || !message.trim()) throw new HttpsError("invalid-argument", "Pesan error wajib diisi.");
  await db.collection("client_error_logs").add({
    uid: auth.uid, message: message.slice(0, 3000),
    stack: typeof stack === "string" ? stack.slice(0, 6000) : "",
    source: typeof source === "string" ? source.slice(0, 80) : "client",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});


const ORDER_STATUS_TEXT = {
  awaiting_confirmation: "Pesanan baru menunggu konfirmasi penjual",
  paid: "Pembayaran saldo berhasil",
  confirmed: "Pesanan telah dikonfirmasi",
  processing: "Pesanan sedang diproses",
  shipped: "Pesanan telah dikirim",
  completed: "Pesanan selesai",
  cancelled: "Pesanan dibatalkan",
  return_requested: "Pembeli mengajukan pengembalian",
  returned: "Pengembalian pesanan diproses",
  disputed: "Pesanan masuk pusat sengketa",
};

exports.notifyMarketplaceOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data?.data();
  if (!order) return;
  const title = "Pesanan Flowa";
  const body = ORDER_STATUS_TEXT[order.status] || "Pesanan baru dibuat";
  await Promise.all([
    sendToUser(order.sellerId, title, body, { type: "marketplace_order", orderId: event.params.orderId }),
    sendToUser(order.buyerId, title, "Pesanan berhasil dibuat", { type: "marketplace_order", orderId: event.params.orderId }),
  ]);
  logger.info("Marketplace order notification dispatched", { orderId: event.params.orderId });
});

exports.notifyMarketplaceOrderStatus = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  const body = ORDER_STATUS_TEXT[after.status] || "Status pesanan diperbarui";
  const recipients = [...new Set([after.buyerId, after.sellerId].filter(Boolean))];
  await Promise.all(recipients.map((uid) =>
    sendToUser(uid, "Pembaruan Pesanan Flowa", body, {
      type: "marketplace_order_status", orderId: event.params.orderId, status: after.status,
    })
  ));
  logger.info("Marketplace order status notification dispatched", { orderId: event.params.orderId, status: after.status });
});
