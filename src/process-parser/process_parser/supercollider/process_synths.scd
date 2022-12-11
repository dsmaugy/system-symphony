(
var system_synth, mem_synth, cpu_synth, grain_synth;
var system_osc_func, cpu_osc_func, new_proc_osc_func, mem_osc_func;
var all_cont_synths;
var stop_osc_func;

s.options.memSize = 128000;
s.waitForBoot({
	~xp_startup = Buffer.read(s, "windows_xp.wav".resolveRelative);

	// synth definitions
		SynthDef(\system_synth, { |out, freq=200, amp=0, upper_harm=1.5|
		var num = 8;
		var spread = rrand(0.4,0.8);
		var attack = rrand(0.05, 0.3);
		var harm = Array.geom(num, 1, upper_harm);
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

	SynthDef(\prayer_bell, { |outbus, t_trig = 1, sing_switch = 0, freq = 2434, amp = 0, decayscale = 1, lag = 10, i_doneAction = 0|
		var sig, input, first, freqscale, mallet, sing;
		freqscale = freq / 2434;
		freqscale = Lag3.kr(freqscale, lag);
		decayscale = Lag3.kr(decayscale, lag);

		mallet = LPF.ar(Trig.ar(t_trig, SampleDur.ir)!2, 10000 * freqscale);
		sing = LPF.ar(
			LPF.ar(
				{
					PinkNoise.ar * Integrator.kr(sing_switch * 0.001, 0.999).linexp(0, 1, 0.01, 1) * amp
				} ! 2,
				2434 * freqscale
			) + Dust.ar(0.1), 10000 * freqscale
		) * LFNoise1.kr(0.5).range(-45, -30).dbamp;
		input = mallet + (sing_switch.clip(0, 1) * sing);


		sig = DynKlank.ar(`[
			[
				(first = LFNoise1.kr(0.5).range(2424, 2444)) + Line.kr(20, 0, 0.5),
				first + LFNoise1.kr(0.5).range(1,3),
				LFNoise1.kr(1.5).range(5435, 5440) - Line.kr(35, 0, 1),
				LFNoise1.kr(1.5).range(5480, 5485) - Line.kr(10, 0, 0.5),
				LFNoise1.kr(2).range(8435, 8445) + Line.kr(15, 0, 0.05),
				LFNoise1.kr(2).range(8665, 8670),
				LFNoise1.kr(2).range(8704, 8709),
				LFNoise1.kr(2).range(8807, 8817),
				LFNoise1.kr(2).range(9570, 9607),
				LFNoise1.kr(2).range(10567, 10572) - Line.kr(20, 0, 0.05),
				LFNoise1.kr(2).range(10627, 10636) + Line.kr(35, 0, 0.05),
				LFNoise1.kr(2).range(14689, 14697) - Line.kr(10, 0, 0.05)
			],
			[
				LFNoise1.kr(1).range(-10, -5).dbamp,
				LFNoise1.kr(1).range(-20, -10).dbamp,
				LFNoise1.kr(1).range(-12, -6).dbamp,
				LFNoise1.kr(1).range(-12, -6).dbamp,
				-20.dbamp,
				-20.dbamp,
				-20.dbamp,
				-25.dbamp,
				-10.dbamp,
				-20.dbamp,
				-20.dbamp,
				-25.dbamp
			],
			[
				20 * freqscale.pow(0.2),
				20 * freqscale.pow(0.2),
				5,
				5,
				0.6,
				0.5,
				0.3,
				0.25,
				0.4,
				0.5,
				0.4,
				0.6
			] * freqscale.reciprocal.pow(0.5)
		], input, freqscale, 0, decayscale);
		DetectSilence.ar(sig, doneAction: i_doneAction);
		Out.ar(outbus, sig * amp);
	}).add;

	SynthDef(\drone, { |out, freq=200, reverb_mix=0.5, reverb_room=0.5, amp=0|
		var chord = [1,1.25,1.5];
		var snd = WhiteNoise.ar();
		var filt1 = BPF.ar(snd, freq * chord[0],0.05);
		var filt2 = BPF.ar(filt1,freq * chord[0],0.05);
		var filt3 = BPF.ar(filt2,freq * chord[0],0.05);
		var filt4 = BPF.ar(filt3,freq * chord[0],0.05);
		var filt5 = BPF.ar(filt4,freq * chord[0],0.05);
		var filt6 = BPF.ar(snd,freq * chord[1],0.05);
		var filt7 = BPF.ar(filt6,freq * chord[1],0.05);
		var filt8 = BPF.ar(filt7,freq * chord[1],0.05);
		var filt9 = BPF.ar(filt8,freq * chord[1],0.05);
		var filt10 = BPF.ar(filt9,freq * chord[1],0.05);
		var filt11 = BPF.ar(snd,freq * chord[2],0.05);
		var filt12 = BPF.ar(filt11,freq * chord[2],0.05);
		var filt13 = BPF.ar(filt12,freq * chord[2],0.05);
		var filt14 = BPF.ar(filt13,freq * chord[2],0.05);
		var filt15 = BPF.ar(filt14,freq * chord[2],0.05);
		var verb = FreeVerb.ar([filt5, filt10,filt15], reverb_mix, reverb_room);
		var sig = Splay.ar(verb, rrand(0.6,1), center:rrand(-0.2, 0.2)) * amp;
		Out.ar(out, sig);
	}).add;

	SynthDef(\strings,{|out= 0 freq = 440 amp = 1.0 gate=1 lforate = 10 lfowidth= 0.5 cutoff= 12000 rq=0.5 pan = 0.0|

		var lfo, pulse, filter, env;

		lfo = LFTri.kr(lforate*[1,1.01],Rand(0,2.0)!2); // non-bad-limiting triangle oscillator

		pulse = Pulse.ar(freq*[1,1.01],lfo*lfowidth+0.5); // Band limited pulse wave generator with pulse width modulation

		filter = RLPF.ar(pulse,cutoff,rq);

		env = EnvGen.kr(Env.adsr(0.01,0.0,1.0,0.5),gate,doneAction:2);

		Out.ar(out,Pan2.ar(Mix(filter)*env*amp*0.5,pan));

	}).add;

	SynthDef(\grain_synth, { |out, gate = 1, amp = 1, rate=0.6, pos=0.5, sndbuf|
		var env, freqdev;
		// use mouse x to control panning
		env = EnvGen.kr(
			Env([0, 1, 0], [1, 1], \sin, 1),
			gate,
			levelScale: amp,
			doneAction: Done.freeSelf);
		Out.ar(out, GrainBuf.ar(2, Impulse.kr(10), 0.5, sndbuf, rate, LFNoise2.kr(pos).range(0, 1)) * amp);
	}).add;

	// wait for all synthdefs to load
	s.sync;
	"SynthDefs added".postln;
	// OSCFunc Definitions - here is where the controls happen
	system_synth = Synth(\system_synth, [\freq, 100, \amp, 0]);
	cpu_synth = Synth(\strings, [\amp, 0]);
	mem_synth = Synth(\drone, [\freq, 800, \amp, 0]);
	grain_synth = Synth(\grain_synth, [\sndbuf, ~xp_startup, \amp, 0]);
	all_cont_synths = [system_synth, mem_synth, cpu_synth, grain_synth];


	system_osc_func = OSCFunc({ |msg, time, addr, recvPort|
		var system_synth_freq_new = msg[1];
		var harm_new = msg[2];
		var system_synth_freq_cur = system_synth.get(\freq);
		[msg, time, addr, recvPort].postln;

	system_synth.set(\freq, system_synth_freq_new, \amp, 0.1);
		grain_synth.set(\rate, msg[2], \pos, msg[1], \amp, 0.15);
	}, '/system');

	cpu_osc_func = OSCFunc({ |msg, time, addr, recvPort|
		// [msg, time, addr, recvPort].postln;
		cpu_synth.set(\freq, msg[1]*10, \amp, 0.02);  // 700 + ((msg[1]/100)*250)
	}, '/top_cpu_usage');

	new_proc_osc_func = OSCFunc({ |msg, time, addr, recvPort|
		// [msg, time, addr, recvPort].postln;

		Synth(\prayer_bell, [\freq, msg[1], \amp, 0.1]);
	}, '/new_proc');

	mem_osc_func = OSCFunc({ |msg, time, addr, recvPort|
		// [msg, time, addr, recvPort].postln;
		mem_synth.set(\freq, msg[1]*15, \amp, 0.5);  // 700 + ((msg[1]/100)*250).
	}, '/top_mem_usage');

	stop_osc_func = OSCFunc({|msg, time, addr, recvPort|
	// [msg, time, addr, recvPort].postln;
		all_cont_synths.do({|item, i|
			item.set(\amp, 0);
		});
	}, '/stop_all');
});
)


/*(
SynthDef(\grain_synth, { |out, gate = 1, amp = 1, rate=0.6, pos=0.5, sndbuf|
    var env, freqdev;
    // use mouse x to control panning
    env = EnvGen.kr(
        Env([0, 1, 0], [1, 1], \sin, 1),
        gate,
        levelScale: amp,
        doneAction: Done.freeSelf);
    Out.ar(out, GrainBuf.ar(2, Impulse.kr(10), 0.5, sndbuf, rate, LFNoise2.kr(pos).range(0, 1)) * amp);
}).add;
)

x = Synth(\buf_grain_test, [\amp, 0.1, \sndbuf, ~xp_startup, \rate, 14, 0.8]);
x.set(\amp, 0.3, \rate, 0, \pos, 0.2)*/


// (
// var system_synth, mem_synth, cpu_synth, r2d2_synth;
// var system_osc_func, cpu_osc_func, new_proc_osc_func, mem_osc_func;
// var all_cont_synths;
// var stop_osc_func;
//
//
// system_synth = Synth(\system_synth, [\freq, 100, \amp, 0]);
// cpu_synth = Synth(\strings, [\amp, 0]);
// mem_synth = Synth(\drone, [\freq, 800, \amp, 0]);
// r2d2_synth = Synth(\system_synth, [\freq, 100, \amp, 0]);
// all_cont_synths = [system_synth, mem_synth, cpu_synth, r2d2_synth];
//
//
// system_osc_func = OSCFunc({ |msg, time, addr, recvPort|
// 	var system_synth_freq_new = msg[1];
// 	var harm_new = msg[2];
// 	var system_synth_freq_cur = system_synth.get(\freq);
// 	[msg, time, addr, recvPort].postln;
//
// 	system_synth.set(\freq, system_synth_freq_new, \amp, 0.1);
// 	r2d2_synth.set(\freq, 10, \upper_harm, harm_new, \amp, 0.01);
// }, '/system');
//
// cpu_osc_func = OSCFunc({ |msg, time, addr, recvPort|
// 	// [msg, time, addr, recvPort].postln;
// 	cpu_synth.set(\freq, msg[1]*10, \amp, 0.02);  // 700 + ((msg[1]/100)*250)
// }, '/top_cpu_usage');
//
// new_proc_osc_func = OSCFunc({ |msg, time, addr, recvPort|
// 	// [msg, time, addr, recvPort].postln;
//
// 	Synth(\prayer_bell, [\freq, msg[1], \amp, 0.1]);
// }, '/new_proc');
//
// mem_osc_func = OSCFunc({ |msg, time, addr, recvPort|
// 	// [msg, time, addr, recvPort].postln;
// 	mem_synth.set(\freq, msg[1]*15, \amp, 0.5);  // 700 + ((msg[1]/100)*250).
// }, '/top_mem_usage');
//
// stop_osc_func = OSCFunc({|msg, time, addr, recvPort|
// 	// [msg, time, addr, recvPort].postln;
// 	all_cont_synths.do({|item, i|
// 		item.set(\amp, 0);
// 	});
// }, '/stop_all');
// )



// b = Synth(\prayer_bell, [\freq, 1000, \amp, 0.02, \sing_switch, 0.9, \t_trig, 1])

// a = Synth(\system_synth, [freq: 179])
// a.set(\upper_harm, 3.2, \freq, 140)
// a = Synth(\drone, [\freq, 800, \amp, 0]);




/*
(
{
	x = RLPF.ar(SinOsc.ar(SinOsc.ar([0.020, 0.019]).range(3, 10)) * SyncSaw.ar(SinOsc.ar(0.01).range(1, 100), SinOsc.ar(0.017).range(300, 1000)), Line.ar(60, 10000, 60*5));
	x = GVerb.ar(x + CombL.ar(x, 10, 0.2, 10));

	// EnvGen.ar(1, doneAction:2) * x * 0.03!2
	Pan2.ar(x * 0.04);
}.play
)*/