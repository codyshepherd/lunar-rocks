import './main.css';
import { playNote } from './audio.js';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

var app = Main.embed(document.getElementById('root'));

registerServiceWorker();

app.ports.play.subscribe(function (args) {
  // args.beat also available
  playNote(args.trackId, args.tone, args.duration);
});
