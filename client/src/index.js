import './main.css';
import { audioContext, playNote } from './audio.js';
import { Main } from './Main.elm';
import WAAClock from 'waaclock';
import registerServiceWorker from './registerServiceWorker';

var app = Main.embed(document.getElementById('root'));

registerServiceWorker();

// setup and start clock
var clock = new WAAClock(audioContext);
clock.start();

var beat = 0;   // current beat
var beats = 8;  // total beats
var bpm = 120;
var tick = 60 / bpm;  // duration of one beat
var play = false;
var score = [];

// process score
app.ports.sendScore.subscribe(function (args) {
    if (args.length > 0) {
        play = true;
        var newScore = [];
        for (var i = 1; i <= beats; i++) {
            newScore.push([]);
            for (var j = 0; j < args.length; j++) {
                if (args[j].beat == i && args[j].duration > 0) {
                    newScore[i-1].push(args[j]);
                }
            }
        }
        score = newScore;
      console.log(score);
    }
    else {
      play = false;
    }
});


// play notes
// schedule notes for a beat, increment beat each time
var loop = clock.callbackAtTime(function() {
  // console.log(beat);
  // play notes for current beat
  if (play) {
    var notes = score[beat];
    for (var i = 0; i < notes.length; i++) {
      // playNote(notes[i].trackId, notes[i].tone, notes[i].duration);
        playNote(notes[i].trackId, notes[i].instrument, notes[i].tone, notes[i].duration);
    }
  };
  beat = (beat + 1) % beats;
}, tick).repeat(tick);
