n = NetAddr("127.0.0.1", NetAddr.langPort);

(
SynthDef(\system_synth, { |out, freq=200, amp=0.2|
	var dur = 8;
	var num = 8;
	var root = 36;
	var spread = rrand(0.4,0.8);
	var attack = rrand(0.05, 0.3);
	var harm = Array.geom(num, 1, 1.5);
	var harma = Array.geom(num, 0.5, 0.8);
	var detune = Array.fill(num, { LFNoise2.kr(1,0.01,1) });
	var source = PinkNoise.ar;
	var bandwidth = Rand(0.001,0.01);
	var generator = [
		SinOsc.ar(freq*harm*detune, mul:harma*0.3).scramble,
		Resonz.ar(source, freq*harm*detune, bandwidth, mul:harma).scramble * 50
	].wchoose([0.2,0.8]);
	var snd = Splay.ar(generator,spread);

	Out.ar(out, snd * amp);
}).add;
)


(
var system_synth;

system_synth = Synth(\system_synth, [freq: 100]);
o = OSCFunc({ |msg, time, addr, recvPort|
	var system_synth_freq_new = msg[1]*15;
	var system_synth_freq_cur = system_synth.get(\freq);
	// var system_synth_freq_diff = system_synth_freq_new - system_synth_freq_cur;
	system_synth_freq_cur.postln;
	[msg, time, addr, recvPort].postln;



	10.do({|i| // system_synth.set(\freq, system_synth_freq_cur + system_synth_freq_diff*(i/10));
		system_synth.get(\freq, { |curr_freq|
			var freq_diff = system_synth_freq_new - curr_freq;
			system_synth.set(\freq, curr_freq + (freq_diff/10));
		})
	})

}, '/system');

)
