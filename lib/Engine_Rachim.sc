// Engine_Rachim

// Inherit methods from CroneEngine
Engine_Rachim : CroneEngine {

	// Rachim specific v0.1.0
	var server;
	var params;
	var buses;
	var syns;
	var oscs;
	// Rachim ^
    

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		// Rachim specific v0.0.1
		var server = context.server;

        SynthDef("jp2",{
            arg busWet,busDry,db=0,freq=40,gate=1,wet=1,dur=1,id=1,attack=10,release=10;
            var note=Clip.kr(freq,10,18000).cpsmidi;
            var detuneCurve = { |x|
                (10028.7312891634*x.pow(11)) -
                (50818.8652045924*x.pow(10)) +
                (111363.4808729368*x.pow(9)) -
                (138150.6761080548*x.pow(8)) +
                (106649.6679158292*x.pow(7)) -
                (53046.9642751875*x.pow(6)) +
                (17019.9518580080*x.pow(5)) -
                (3425.0836591318*x.pow(4)) +
                (404.2703938388*x.pow(3)) -
                (24.1878824391*x.pow(2)) +
                (0.6717417634*x) +
                0.0030115596
            };
            var centerGain = { |x| (-0.55366 * x) + 0.99785 };
            var sideGain = { |x| (-0.73764 * x.pow(2)) + (1.2841 * x) + 0.044372 };
            var center = Mix.new(SawDPW.ar(freq, Rand()));
            var detuneFactor = freq * detuneCurve.(LFNoise2.kr(1/dur).range(0.3,0.5));
            var freqs = [
                (freq - (detuneFactor * 0.11002313)),
                (freq - (detuneFactor * 0.06288439)),
                (freq - (detuneFactor * 0.01952356)),
                (freq + (detuneFactor * 0.01991221)),
                (freq + (detuneFactor * 0.06216538)),
                (freq + (detuneFactor * 0.10745242))
            ];
            var side = Mix.fill(6, { |n|
                SawDPW.ar(freqs[n], Rand(0, 2))
            });

            var mix = LFNoise2.kr(1/dur).range(0.7,1.0);
            var sig =  (center * centerGain.(mix)) + (side * sideGain.(mix));
            sig = HPF.ar(sig, freq);
            sig = BLowPass.ar(sig,freq*LFNoise2.kr(1/dur).range(4,20),1/0.707);
            sig = sig * EnvGen.ar(Env.adsr(attack,1,1,release),gate:gate);
            sig = sig * 12.neg.dbamp * Lag.kr(db,dur/2).dbamp;
            sig = Pan2.ar(sig);
            Out.ar(busDry,sig*(1-wet));
            Out.ar(busWet,sig*wet);
        }).send(server);

        SynthDef("sine",{
            arg busWet,busDry,db=0,freq=40,gate=1,wet=1,dur=1,id=1,attack=1,release=1;
            var note=Vibrato.kr(freq,LFNoise2.kr(1/dur).range(0.1,1),LFNoise2.kr(1/dur).range(0.001,0.007),0.01).cpsmidi;
            var snd=Pulse.ar([note-Rand(0,0.05),note+Rand(0,0.05)].midicps,SinOsc.kr(Rand(1,3),Rand(0,pi)).range(0.3,0.7));
            snd=snd+PinkNoise.ar(SinOsc.kr(1/LFNoise2.kr(1/12).range(dur*0.5,dur),Rand(0,pi)).range(0.0,1.0));
            snd=RLPF.ar(snd,note.midicps*6,0.707);
            snd=Balance2.ar(snd[0],snd[1],Rand(-1,1));
            snd = snd * EnvGen.ar(Env.adsr(attack,1,1,release),gate:gate);
            snd = snd * 24.neg.dbamp * Lag.kr(db,dur/4).dbamp;
            Out.ar(busDry,snd*(1-wet));
            Out.ar(busWet,snd*wet);
        }).send(server);

        SynthDef("out",{
            arg busWet, busDry;
            var snd2;
            var shimmer=0.25;
            var sndWet=In.ar(busWet,2);
            var sndDry=In.ar(busDry,2);
            sndWet = DelayN.ar(sndWet, 0.03, 0.03);
            sndWet = sndWet + PitchShift.ar(sndWet, 0.13, 2,0,1,1*shimmer/2);
            sndWet = sndWet + PitchShift.ar(sndWet, 0.1, 4,0,1,0.5*shimmer/2);
            sndWet=Fverb.ar(sndWet[0],sndWet[1],117,
                decay:VarLag.kr(LFNoise0.kr(1/3),3).range(50,100),
                tail_density:VarLag.kr(LFNoise0.kr(1/3),3).range(50,100),
            );
            snd2 = sndWet + sndDry;
            snd2=AnalogTape.ar(snd2,0.9,0.9,0.7);
            snd2=SelectX.ar(LFNoise2.kr(1/4).range(0,0.4),[snd2,AnalogChew.ar(snd2,1.0,0.5,0.5)]);
            //snd2=SelectX.ar(LFNoise2.kr(1/10).range(0,0.6),[snd2,AnalogDegrade.ar(snd2,0.2,0.2,0.5,0.5)]);
            //snd2=SelectX.ar(LFNoise2.kr(1/12).range(0,0.3),[snd2,AnalogLoss.ar(snd2,0.5,0.5,0.5,0.5)]);
            snd2=snd2.tanh*0.75;
            snd2=HPF.ar(snd2,20);
            snd2=BPeakEQ.ar(snd2,24.midicps,1,3);
            snd2=BPeakEQ.ar(snd2,660,1,-3);
            snd2=SelectX.ar(LFNoise2.kr(1/4).range(0.4,0.8),[snd2,Fverb.ar(snd2[0],snd2[1],100,decay:VarLag.kr(LFNoise0.kr(1/3),3).range(60,96))]);
            snd2=snd2*EnvGen.ar(Env.new([48.neg,0],[3])).dbamp;
            snd2 = Compander.ar(snd2,snd2)/2;
            snd2 = Limiter.ar(snd2,0.9);
            snd2 = snd2 * EnvGen.ar(Env.new([0,1],[3]));
            Out.ar(0,snd2);
        }).send(server);


		// initialize variables
		params = Dictionary.new();
		syns = Dictionary.new();
		buses = Dictionary.new();
		oscs = Dictionary.new();

		server.sync;
		
		// define buses
		buses.put("busDry",Bus.audio(server,2));
		buses.put("busWet",Bus.audio(server,2));
		server.sync;

		// main out
		syns.put("out",Synth.tail(server,"out",[
			busDry: buses.at("busDry"),
			busWet: buses.at("busWet"),
		]));
		server.sync;

        // create synths
        4.do({ arg i;
            syns.put(i+1,Synth.head(server,"sine",[
                \id: i+1,
                \db: -96,
                \gate: 0,
                \busDry: buses.at("busDry"),
                \busWet: buses.at("busWet"),
                \dur: rrand(3,10),
                \wet: rrand(500,1000)/1000.0,
            ]));
        });
        syns.put(5,Synth.head(server,"jp2",[
            \id: 5,
            \db: -96,
            \gate: 0,
            \busDry: buses.at("busDry"),
            \busWet: buses.at("busWet"),
            \dur: rrand(3,10),
            \wet: rrand(800,1000)/1000.0,
        ]));

		"done loading.".postln;

		this.addCommand("set","isf",{ arg msg;
			var id=msg[1];
			var k=msg[2];
			var v=msg[3];
            [id,k,v].postln;
            syns.at(id).set(k,v);
		});

	}


	free {
		oscs.keysValuesDo({ arg k, val;
			val.free;
		});
		syns.keysValuesDo({ arg k, val;
			val.free;
		});
		buses.keysValuesDo({ arg k, val;
			val.free;
		});
	}
}
