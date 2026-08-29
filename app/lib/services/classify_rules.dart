/// Direct port of `src/agents/nlp/index.ts`'s `classify()` method from the
/// real Scasi-AI backend. It's a pure keyword rule engine — no LLM call, no
/// API key needed — so this is copied logic, not a simplification.
class ClassifyResult {
  final String category;
  final double confidence;
  final int priority;
  final String reason;
  ClassifyResult(this.category, this.confidence, this.priority, this.reason);
}

ClassifyResult classifyEmail({required String subject, required String snippet, String? from}) {
  final text = '$subject $snippet ${from ?? ''}'.toLowerCase();
  bool match(List<String> keywords) => keywords.any((k) => text.contains(k));

  if (match(['urgent', 'asap', 'immediately', 'action required', 'critical', 'emergency', 'respond now'])) {
    return ClassifyResult('urgent', 0.92, 90, 'Urgent keywords detected');
  }
  if (match(['invoice', 'payment due', 'billing statement', 'receipt', 'bank transfer', 'bank account', 'transaction alert', 'refund', 'overdue', 'amount due', 'payslip', 'salary credit'])) {
    return ClassifyResult('financial', 0.88, 75, 'Financial keywords detected');
  }
  if (match(['action required', 'please review', 'your approval', 'please confirm', 'follow up on', 'kindly assist', 'approval needed', 'your response is needed'])) {
    return ClassifyResult('action_required', 0.85, 70, 'Action request detected');
  }
  if (match(['meeting', 'interview', 'schedule', 'calendar invite', 'zoom', 'google meet', 'teams call', 'appointment', 'standup', 'sync'])) {
    return ClassifyResult('meeting', 0.87, 65, 'Meeting/scheduling keywords detected');
  }
  if (match(['linkedin', 'twitter', 'instagram', 'facebook', 'github notification', 'mentioned you', 'connection request', 'started following', 'noreply@', 'social notification'])) {
    return ClassifyResult('social', 0.90, 20, 'Social network email detected');
  }
  if (match(['unsubscribe', 'sale', '% off', 'deal', 'offer', 'discount', 'coupon', 'promo', 'limited time', 'shop now', 'buy now', 'free trial', 'upgrade now'])) {
    return ClassifyResult('promotional', 0.91, 15, 'Promotional keywords detected');
  }
  if (match(['newsletter', 'digest', 'weekly update', 'monthly report', 'announcement', 'release notes', 'changelog', 'alert', 'no-reply', 'noreply'])) {
    return ClassifyResult('newsletter', 0.83, 25, 'Newsletter or digest email');
  }
  if (match(['congratulations', 'you have won', 'click here to claim', 'verify your account now', 'suspicious', 'out of office auto-reply'])) {
    return ClassifyResult('spam', 0.80, 5, 'Spam-like keywords detected');
  }
  if (match(['hey', 'hi there', 'dear friend', 'hope you are', 'miss you', 'family', 'mom', 'dad', 'brother', 'sister'])) {
    return ClassifyResult('personal', 0.75, 55, 'Personal email signals detected');
  }
  return ClassifyResult('fyi', 0.60, 30, 'General informational email');
}
