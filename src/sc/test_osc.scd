n = NetAddr("127.0.0.1", NetAddr.langPort);

o = OSCFunc({ arg msg, time, addr, recvPort; [msg, time, addr, recvPort].postln; }, '/test');

OSCFunc.trace(false);