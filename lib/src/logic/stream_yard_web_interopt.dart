import 'package:streamyard_livestream/streamyard_livestream.dart';

class StreamYardWebInteropt {
  static StreamYardWebInteropt get instance => StreamYardWebInteropt.create();

  StreamYardWebInteropt._();
  StreamYardWebInteropt.create() : this._();

  String streamUrl(String streamId) => 'https://streamyard.com/watch/$streamId';
  String autoJoinStream({required StreamYardUser user}) {
    return '''
(function () {

  const CONFIG = {
    firstName: '${user.firstName}',
    lastName: '${user.lastName}',
    debug: true,
  };

  function log(msg) {
    if (CONFIG.debug) {
      console.log('[StreamYard Inject]', msg);
    }
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('logMessage', msg);
    }
  }

  function sleep(ms) {
    return new Promise(r => setTimeout(r, ms));
  }

  function waitFor(fn, timeout = 15000) {
    return new Promise((resolve, reject) => {
      const start = Date.now();
      const timer = setInterval(() => {
        const res = fn();
        if (res) {
          clearInterval(timer);
          resolve(res);
        }
        if (Date.now() - start > timeout) {
          clearInterval(timer);
          reject('timeout');
        }
      }, 300);
    });
  }

  function setReactInputValue(input, value) {
    const setter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype,
      'value'
    ).set;

    setter.call(input, value);
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  async function openJoinModal() {
    log('waiting join button');

    const joinBtn = await waitFor(() =>
      [...document.querySelectorAll('button')]
        .find(b => b.innerText.trim().toLowerCase() === 'join')
    );

    joinBtn.scrollIntoView({ behavior: 'smooth', block: 'center' });
    joinBtn.click();

    log('join modal opened');
    return true;
  }

  async function fillForm() {
    log('waiting inputs');

    const inputs = await waitFor(() =>
      [...document.querySelectorAll('input')]
        .filter(i =>
          i.placeholder &&
          (
            i.placeholder.toLowerCase().includes('first') ||
            i.placeholder.toLowerCase().includes('last')
          )
        )
    );

    const first = inputs.find(i => i.placeholder.toLowerCase().includes('first'));
    const last = inputs.find(i => i.placeholder.toLowerCase().includes('last'));

    if (!first || !last) {
      throw 'inputs not found';
    }

    setReactInputValue(first, CONFIG.firstName);
    setReactInputValue(last, CONFIG.lastName);

    log('name filled');

    await sleep(500);

    const submitBtn = await waitFor(() =>
      [...document.querySelectorAll('button')]
        .find(b => b.innerText.trim().toLowerCase() === 'join')
    );

    submitBtn.focus();
    submitBtn.style.outline = '3px solid #7CFF00';

    log('ready for user click');

    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('updateState', {
        state: 'ready',
        message: 'Tap Join to enter StreamYard'
      });
    }
  }

  async function start() {
    try {
      log('inject start');
      await openJoinModal();
      await sleep(1200);
      await fillForm();
    } catch (e) {
      log('inject failed: ' + e);
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('updateState', {
          state: 'error',
          message: String(e)
        });
      }
    }
  }

  setTimeout(start, 3000);

})();
''';
  }
}
