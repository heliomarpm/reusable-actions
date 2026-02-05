log() { echo "▶ $1"; }
log_info() { echo "ℹ️ $1"; }
log_error() { echo "❌ $1"; }
log_success() { echo "✅ $1"; }
log_warn() { echo "⚠️ $1"; }

log_section() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
