/* ==========================================================================
   IMPACT NATION GIVING — LANDING PAGE JAVASCRIPT
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // ── Copy Account Number ──────────────────────────────────────────
  const copyBtn = document.getElementById('copyAccountBtn');
  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const accountNum = '3005256062';
      navigator.clipboard.writeText(accountNum).then(() => {
        const originalText = copyBtn.innerText;
        copyBtn.innerText = 'Copied! ✓';
        copyBtn.style.background = '#10B981';
        copyBtn.style.color = '#FFFFFF';
        setTimeout(() => {
          copyBtn.innerText = originalText;
          copyBtn.style.background = '';
          copyBtn.style.color = '';
        }, 2200);
      }).catch(() => {
        // Fallback
        alert('Account Number: 3005256062 (GTBank)');
      });
    });
  }

  // ── Modal Handling (How to Install APK) ───────────────────────────
  const openModalBtn = document.getElementById('openInstallGuideBtn');
  const closeModalBtn = document.getElementById('closeModalBtn');
  const modalOverlay = document.getElementById('installModal');

  if (openModalBtn && modalOverlay) {
    openModalBtn.addEventListener('click', (e) => {
      e.preventDefault();
      modalOverlay.classList.add('active');
    });
  }

  if (closeModalBtn && modalOverlay) {
    closeModalBtn.addEventListener('click', () => {
      modalOverlay.classList.remove('active');
    });
  }

  if (modalOverlay) {
    modalOverlay.addEventListener('click', (e) => {
      if (e.target === modalOverlay) {
        modalOverlay.classList.remove('active');
      }
    });
  }

  // ── Generate Dynamic Real Scannable QR Code ─────────────────────
  const qrContainer = document.getElementById('qrCodeContainer');
  if (qrContainer) {
    // If testing on localhost, phone camera cannot access localhost IP, so provide live fallback
    const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
    const downloadUrl = isLocal
      ? 'https://impact-nation-fund-raising.web.app/downloads/impact-nation-giving.apk'
      : `${window.location.origin}/downloads/impact-nation-giving.apk`;

    qrContainer.innerHTML = '';
    if (typeof QRCode !== 'undefined') {
      new QRCode(qrContainer, {
        text: downloadUrl,
        width: 140,
        height: 140,
        colorDark: '#080D1A',
        colorLight: '#FFFFFF',
        correctLevel: QRCode.CorrectLevel.M
      });
    }
  }

  // ── Navbar background scroll effect ──────────────────────────────
  const navbar = document.querySelector('.navbar');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      navbar.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.6)';
    } else {
      navbar.style.boxShadow = 'none';
    }
  });
});
