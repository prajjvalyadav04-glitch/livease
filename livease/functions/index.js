const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const STATUS_LABELS = {
  open: "Open",
  in_progress: "In progress",
  resolved: "Resolved",
};

/**
 * New notice -> push to every resident (they all subscribe to the "society"
 * topic after login; see lib/services/notification_service.dart).
 */
exports.notifyNewNotice = onDocumentCreated("notices/{noticeId}", async (event) => {
  const notice = event.data && event.data.data();
  if (!notice) return;

  const body = String(notice.body || "");
  await getMessaging().send({
    topic: "society",
    notification: {
      title: notice.title || "New notice",
      body: body.length > 120 ? `${body.slice(0, 117)}...` : body,
    },
    data: { type: "notice", id: event.params.noticeId },
    android: { priority: "high" },
  });
});

/**
 * Complaint status changed -> push to the resident who raised it.
 */
exports.notifyComplaintUpdate = onDocumentUpdated(
  "complaints/{complaintId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after || before.status === after.status) return;

    const userSnap = await getFirestore()
      .collection("users")
      .doc(after.residentId)
      .get();
    const token = userSnap.exists ? userSnap.data().fcmToken : null;
    if (!token) return;

    try {
      await getMessaging().send({
        token,
        notification: {
          title: "Complaint update",
          body: `"${after.title}" is now ${STATUS_LABELS[after.status] || after.status}`,
        },
        data: { type: "complaint", id: event.params.complaintId },
        android: { priority: "high" },
      });
    } catch (err) {
      // A stale token should not fail the whole function.
      console.warn("Could not send complaint push:", err.message);
    }
  }
);
