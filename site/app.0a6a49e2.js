/* dotfiles.marcopontili.com: cookieless analytics, the copy buttons, the FAQ
   accordion, and motion that waits for its figure to be on screen. */

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

/* Start each [data-play] animation once the whole figure is visible, or, for a
   figure taller than the viewport, once it fills most of it. Pausing lives in
   the stylesheet. */
(function () {
  var pending = Array.prototype.slice.call(document.querySelectorAll('[data-play]'));
  if (!pending.length) return;
  var queued = false;

  function check() {
    queued = false;
    var room = window.innerHeight;
    pending = pending.filter(function (el) {
      var box = el.getBoundingClientRect();
      var shown = Math.min(box.bottom, room) - Math.max(box.top, 0);
      if (shown < Math.min(box.height - 2, room * 0.85)) return true;
      el.classList.add('in-view');
      return false;
    });
    if (!pending.length) {
      window.removeEventListener('scroll', schedule);
      window.removeEventListener('resize', schedule);
    }
  }

  function schedule() {
    if (queued) return;
    queued = true;
    window.requestAnimationFrame(check);
  }

  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', schedule);
  check();
})();

/* Run each [data-run] loop only while it is on screen, so it starts with the
   first card when the reader arrives and stops burning frames once they leave. */
(function () {
  var loops = document.querySelectorAll('[data-run]');
  Array.prototype.forEach.call(loops, function (el) {
    if (!('IntersectionObserver' in window)) {
      el.classList.add('on-screen');
      return;
    }
    new IntersectionObserver(
      function (entries) {
        el.classList.toggle('on-screen', entries[0].isIntersecting);
      },
      { threshold: 0.3 }
    ).observe(el);
  });
})();

/* FAQ: animate the height of each answer as it opens and closes. */
(function () {
  var motion = window.matchMedia('(prefers-reduced-motion: no-preference)');
  if (!('animate' in Element.prototype)) return;

  Array.prototype.forEach.call(document.querySelectorAll('.faq details'), function (item) {
    var summary = item.querySelector('summary');
    var running = null;
    var closing = false;

    summary.addEventListener('click', function (event) {
      if (!motion.matches) return;
      event.preventDefault();
      closing = running ? !closing : item.open;
      var from = item.offsetHeight;
      if (running) running.cancel();
      item.open = true;
      item.classList.add('is-animating');
      var to = closing ? summary.offsetHeight + 2 : item.offsetHeight;
      running = item.animate(
        { height: [from + 'px', to + 'px'] },
        { duration: 260, easing: 'cubic-bezier(0.2, 0, 0, 1)' }
      );
      running.onfinish = function () {
        running = null;
        item.classList.remove('is-animating');
        if (closing) item.open = false;
      };
    });
  });
})();
