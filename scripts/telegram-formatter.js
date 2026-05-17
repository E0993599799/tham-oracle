// Telegram Message Formatter — Convert Oracle messages to human-readable format

function formatForTelegram(data) {
  if (typeof data === 'string') {
    return data; // Already formatted
  }

  if (data.status === 'COMPLETED' || data.status === '✅') {
    return `✅ ${data.title || 'Task'} — COMPLETE\n${data.message || ''}`;
  }

  if (data.status === 'IN_PROGRESS' || data.status === '🟡') {
    return `🟡 ${data.title || 'Task'} — IN PROGRESS\n${data.message || ''}`;
  }

  if (data.status === 'ERROR' || data.status === '❌') {
    return `❌ ${data.title || 'Error'}\n${data.error || data.message || ''}`;
  }

  if (data.status === 'ALERT' || data.status === '🔴') {
    return `🔴 ALERT: ${data.message || data.title || ''}\nAction: ${data.action || ''}`;
  }

  if (data.agent) {
    return `🔷 ${data.agent} — ${data.message || data.status || ''}\nTime: ${data.timestamp || ''}`;
  }

  if (data.progress) {
    return `📊 Progress: ${data.progress}%\n${data.message || ''}\nTime: ${data.eta || ''}`;
  }

  // Fallback to JSON compact format
  return JSON.stringify(data, null, 2);
}

function formatFromTelegram(message) {
  // Parse Telegram message and convert to prompt
  // Examples:
  // "temperature phase 1 status" → prompt
  // "deploy orry" → command
  // "check lanes" → query

  const cmd = message.toLowerCase().trim();

  if (cmd.includes('temperature') && cmd.includes('status')) {
    return '/recap temperature';
  }

  if (cmd.includes('deploy') && cmd.includes('orry')) {
    return 'Deploy ORRY ERP to Vercel';
  }

  if (cmd.includes('check') && cmd.includes('lanes')) {
    return 'Check all lane status and report';
  }

  if (cmd.includes('status')) {
    return '/recap';
  }

  // Passthrough as prompt
  return message;
}

module.exports = {
  formatForTelegram,
  formatFromTelegram
};
