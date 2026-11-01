import { Socket } from '/phoenix/phoenix.mjs';
import { LiveSocket } from '/live-view/phoenix_live_view.esm.js';
import ArmatureToolbar from '/assets/armature-toolbar.js';

if (document.querySelector('[data-phx-main]')) {
  const liveSocket = new LiveSocket('/live', Socket, {
    hooks: { ArmatureToolbar },
    params: { _csrf_token: document.querySelector('meta[name="csrf-token"]').content },
  });
  liveSocket.connect();
}
