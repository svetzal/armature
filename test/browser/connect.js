import { Socket } from '/phoenix/phoenix.mjs';
import { LiveSocket } from '/live-view/phoenix_live_view.esm.js';

if (document.querySelector('[data-phx-main]')) {
  const liveSocket = new LiveSocket('/live', Socket, {
    params: { _csrf_token: document.querySelector('meta[name="csrf-token"]').content },
  });
  liveSocket.connect();
}
