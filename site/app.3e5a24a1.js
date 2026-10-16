/* dotfiles.marcopontili.com: cookieless analytics and the copy buttons. */

/* Self-hosted Matomo at mt.marcopontili.com: no cookies, Do Not Track honoured. */
var _paq = (window._paq = window._paq || []);
_paq.push(['setDoNotTrack', true]);
_paq.push(['disableCookies']);
_paq.push(['setRequestMethod', 'POST']);
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function () {
  var u = 'https://mt.marcopontili.com/';
  var p = 'm/';
  _paq.push(['setTrackerUrl', u + p]);
  _paq.push(['setSiteId', '8']);
  var d = document,
    g = d.createElement('script'),
    s = d.getElementsByTagName('script')[0];
  g.async = true;
  g.src = u + p;
  s.parentNode.insertBefore(g, s);
})();

/* Copy buttons: write only, the clipboard is never read. */
(function () {
  var status = document.getElementById('copy-status');

  function fallbackCopy(text) {
    var area = document.createElement('textarea');
    area.value = text;
    area.setAttribute('readonly', '');
    area.className = 'visually-hidden';
    document.body.appendChild(area);
    area.select();
    var ok = false;
    try {
      ok = document.execCommand('copy');
    } catch (e) {
      ok = false;
    }
    document.body.removeChild(area);
    return ok ? Promise.resolve() : Promise.reject(new Error('copy failed'));
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () {
        return fallbackCopy(text);
      });
    }
    return fallbackCopy(text);
  }

  function announce(message) {
    if (!status) return;
    status.textContent = '';
    window.setTimeout(function () {
      status.textContent = message;
    }, 50);
  }

  Array.prototype.forEach.call(document.querySelectorAll('[data-copy]'), function (button) {
    var label = button.querySelector('.copy-label');
    var source = document.getElementById(button.getAttribute('data-copy'));
    if (!source || !label) return;
    var timer;
    button.hidden = false;
    button.addEventListener('click', function () {
      copyText(source.textContent.replace(/\s+$/, '') + '\n').then(
        function () {
          button.setAttribute('data-state', 'done');
          label.textContent = 'Copied';
          announce(button.getAttribute('aria-label').replace(/^Copy/, 'Copied'));
        },
        function () {
          label.textContent = 'Select';
          announce('Copy failed. Select the commands and copy them by hand.');
        }
      );
      window.clearTimeout(timer);
      timer = window.setTimeout(function () {
        button.removeAttribute('data-state');
        label.textContent = 'Copy';
      }, 2000);
    });
  });
})();
