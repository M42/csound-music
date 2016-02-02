<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

;; HEADER
sr = 44100
ksmps = 8
nchnls = 2
0dbfs = 32767
#define VOL#30000#



;; SLIDE FLUTE
; Our first instrument will be a slide flute modelled after a paper by Perry Cook.
; The flute takes a flow input, adds a bit of noise and models the embouchure
; and the body of the flute, relating them by a cubic equation. This cubic
; equation is an approximation for a sigmoid function, reppresenting the changes
; of pression in the air flow. When the pression is bigger, the resistance to the new
; injected air is smaller. The length of the bore is what determines the pitch.
;
; It uses also a low-pass filter to model the bore of the flute, and two delays in
; order to model the length of the embouchure and the body.
; 
; The original paper, by Perry Cook, can be read here:
; https://ccrma.stanford.edu/files/papers/stanm80.pdf
;
; Used techniques:
; * Physical modelling
; * Substractive synthesis
;
instr 1

	;; Variable initialization.
	; It is important to notice that the length of the embouchure is
	; half of the length of the bore. As the instrument is sightly undertuned
	; due to the delays introduced by the filter, we substract 8 samples to
	; tune it correctly.
	afeedback init 0
	idur = p3
	iamp = p4
	ifreq = cpspch(p5)
	ipression = p6
	ibreath   = p7
	iboredelay = 1/ifreq - 8/sr
	iembdelay  = iboredelay/2
	
	;; Feedback factors
	; These values have been obtained empirically,
	; trying to achieve a natural sound.
	ifeed1    = 0.45
	ifeed2    = 0.4

	;; Envelope
	; Linear envelope
	kenvelope linseg 0, 0.05, 1.1, 0.2, 1, idur-0.30, 1, 0.05, 0
	kpress = ipression*kenvelope*0.99
	
	;; Instrument
	; Random-generated noise
	anoise rand kpress
	anode1 = anoise*ibreath + kpress
	anode2 = anode1 + afeedback * ifeed1
	
	; Embouchure delay
	aemb delay anode2, iembdelay		
	apol   = aemb - aemb*aemb*aemb
	anode3 = apol + afeedback * ifeed2

	; Low-pass filter
	aexit tone anode3, 2000

	; Flute bore delay
	afeedback delay aexit, iboredelay
	
	aout = aexit*kenvelope*iamp
	outs aout,aout

endin



;; GRANULAR TEXTURE
; A granular texture. A granular effect is acheived from a
; wav input. A linear envelope is applied. Window parameters
; have been obtained empirically, trying to achieve the desired
; sound.
;
; The sound is positioned using the Charles Dodge's formula. 
; And the motion is modeled with a linear interpolation.
; Used techniques:
; * Granular synthesis
; * Stereo positioning
; * Gaussian envelope
instr 2
	idur      = p3
	kamp      = p4
	kpitch    = p5
	kdens     = p6
	iinitpan  = p7
    ifinalpan = p8
	kampoff   = 0
	kpitchoff = 100
	kgdur     = 0.6
	igfn      = 12
	iwfn      = 11
	imgdur    = 2 
 
	;kcps = 1/idur	 
	;kenv1 oscil kamp/2, 1, 15  
 	; Linear envelope
 	; Fixed rise:decay ratio, an user controlled envelope is
 	; used in other instruments.
	irise  = 0.05 * idur
	idecay = 0.5 * idur
	kenv linen kamp, irise, idur, idecay 
 
	; Motion
	kpan line iinitpan, idur, ifinalpan 

	; Granular texture
	aout grain kenv, kpitch, kdens, kampoff, kpitchoff, kgdur, igfn, iwfn, imgdur
	
	; Panned output
	; Using sqrt, as proposed by Charles Dodge
	outs aout*sqrt(1-kpan), aout*sqrt(kpan)
endin



; VIOLIN
; An instrument created from a violin spiccato sample, using
; analysis with the opcode 'pvanal'. The violin plays a C3 in 0.75s.
; The duration and frequency of the original sound can be changed.
; A reverberation effect is added.
;
; This technique is very slow. This code is intended to be rendered into a
; WAV file in order to avoid xruns in not very fast CPUs. If the code
; was intended to be used for live audio, it should use a more efficient
; technique, such as the hetro opcode.
;
; Used techniques:
; * Analysis and resynthesis
; * Arbitrary-speed reading of samples
; * Reverberation and delay
instr 3
	iffreq = cpspch(p5)    ; Final frequency
	iofreq = 263           ; Original frequency (C3)
	kfrqm  = iffreq/iofreq ; Frequency multiplier
	idur   = 0.75          ; Real length of the audio file
	ivol   = p4/0dbfs      ; Relative volume
	
	; PVOC needs a pointer reading the file.
	; The supplied pointer reads the file linearly, with a
	; speed depending on the duration of the note in the score.
	klect line 0, p3, 0.75
	aviolin pvoc klect, kfrqm, "violin.voc"	
	
	; Reverb effect
	ireverb = 0.2
	aout reverb aviolin, ireverb
	
	outs aout*ivol,aout*ivol
endin



; CLARINET
; An additive-synthesized clarinet. Built with multiple 
; oscillators. A more concise version could be written using
; the GEN10 routine.
; A flanger effect is added.
;
; Used techniques:
; * Flanger effect
; * 
instr 4
	
	idur  = abs(p3)
	iamp  = p4
	ifreq = cpspch(p5)
	ifeed = p6
	imdel = p7

	aout1	oscil 	10,  ifreq
	aout2	oscil 	5,   ifreq * 2
	aout3	oscil 	3.3, ifreq * 3
	aout4	oscil 	2.5, ifreq * 4
	aout5	oscil 	2,   ifreq * 5
	aout6	oscil 	1.6, ifreq * 6
	aout7	oscil 	1.4, ifreq * 7
	aout8	oscil 	1.25,ifreq * 8
	aout9	oscil 	1.1, ifreq * 9
	aout10	oscil 	1,   ifreq * 10
	
	isum = 10 + 5 + 3.3 + 2.5 + 2 + 1.6 + 1.4 + 1.25 + 1.1 + 1
	inorm = iamp / isum
	
	kamp linen inorm, 0.1, idur, idur - 0.1
	
	atot = kamp * (aout1 + aout2 + aout3 + aout4 + aout5 + aout6 + aout7 + aout8 + aout9 + aout10)

	; Flanger distortion effect
	kfeedback = ifeed
	adel linseg 0, idur/2, imdel, idur/2, 0
	aout flanger atot, adel, kfeedback
	
	outs aout,aout

endin



; RISSET ARPEGGIO
; The Risset arpeggio is a technique used by Jean-Claude Risset.
; It creates an arpeggio with beating patterns created from closely
; spaced sinusoids. It is an example of additive synthesis.
; 
; An explanation on the use of the use of the Risset arpeggio and its
; historical background can be read in the Csound Journal:
; http://csoundjournal.com/issue17/bain_risset_arpeggio.html
;
; The amplitude is regulated by an user-controlled linear envelope.
; 
; Used techniques:
; * Additive synthesis
; * Linear envelope
instr 5
	idur   = p3
	iamp   = p4
	ifreq  = cpspch(p5)
	idelta = p6
	iwave  = 14
	
	; Linear envelope
	irise  = p7
	idecay = p8
	aamp linen iamp, irise, idur, idecay

	; Oscilators	
	acomp1 oscil    aamp,ifreq,         iwave             
	acomp2 oscil    aamp,ifreq+idelta,  iwave
	acomp3 oscil    aamp,ifreq-idelta,  iwave
	acomp4 oscil    aamp,ifreq+idelta*2,iwave         
	acomp5 oscil    aamp,ifreq-idelta*2,iwave
	acomp6 oscil    aamp,ifreq+idelta*3,iwave
	acomp7 oscil    aamp,ifreq-idelta*3,iwave
	acomp8 oscil    aamp,ifreq+idelta*4,iwave
	acomp9 oscil    aamp,ifreq-idelta*4,iwave
	
	aout = acomp1+acomp2+acomp3+acomp4+acomp5+acomp6+acomp7+acomp8+acomp9
	outs aout,aout
endin

; FM PAD
; A simple instrument using Frequency Modulation.
; It defines a modulating and carrier signals whose parameters
; can be changed dinamically. Another way to construct this 
; instrument would be using the 'foscil' opcode.
; 
; Used techniques:
; * FM Modulation
; * Octave-dot-pitch notation
; * Linear envelope
; * Panned output
instr 6
	idur   = p3
	iamp   = p4
	ifreq  = cpspch(p5)
	imamp  = p6
	imfreq = p7
	ipan   = p8
	iwave  = p9
	
	; Amplitude linear envelope
	irise  = 0.05 * idur
	idecay = 0.5 * idur
	kamp linen iamp, irise, idur, idecay
	
	; Modulating and carrier signals
	amodulating oscil imamp, imfreq, -1
	acarrier    oscil kamp, ifreq + amodulating, iwave
	
	aout = acarrier
	
	; Panned output using sqrt to keep rsm as an invariant
	; as proposed by Charles Dodge
	outs aout*sqrt(1-p8), aout*sqrt(p8)
endin


; RISSET HIHAT
; The characteristic envelope of a hihat is achieved using
; an exponetial decreasing envelope instead of the usual linear one.
; 
; Used techniques:
; * Random numbers
; * Exponential envelope
instr 9
	idur = p3
	iamp = p4
	ifreq = p5
	irandf = p6
	isinewave = 10
	
	; Exponential envelope
	kenv expon 1, idur, 0.0001
	
	; Random noise
	; The randi opcode generates random numbers at the
	; specified frequency. If this frequency is less than the
	; sampling frequency, it uses linear interpolation. This
	; can be used in order to achieve a more "metallic" sound.
	arandom randi iamp, irandf
	ahihat oscil arandom, ifreq, isinewave
	
	aout = ahihat*kenv	
	outs aout, aout
endin

</CsInstruments>
	
<CsScore>

#define Risset #i5#
#define TRN #0.05#
#define C3 #130.81#

;; FUNCTIONS

; Pure sine wave. 
; Uses GEN10, which generates the wave from its harmonic series.
f10 0 16384 10 1

; Hanning window.
; Uses GEN20, which generates windows used to smooth the sound.
f11 0 512   20 2

; Beats.
; Uses GEN1, which reads the waveshape from a file.
; Table size is specially large due to the size of the file.
f12 0 131072 1 "beats.wav" 0 0 0

; Enriched sine wave
; Using GEN10 to create a wave made up of three waves.
f13 0 16384 10 1 0.5 0.25

; Risset Arpeggio
; Using GEN10 in order to generate a complex waveshape.
f14 0 4096 10 1  0  0  0  .7 .7 .7 .7 .7 .7

; Gaussian window
; Using GEN20. Used to create a gaussian envelope
f15 0 512 20 2


s
; FM Pad
; Init        Dur Amp Pitch MAmp MFreq Pan Wave
i6  0        0.5  5000 7.00  20         600      0.1   13
i6  0.25   .  .          7.07  .         .                    >    .
i6  0.5    .   .          8.00  .         .                     >   .
i6  0.75 .   .          8.02  .         .                     >   .
i6  1       .  .          8.04  .         .                      >    .
i6  1.25 .  .          8.07  .         .                      >    .
i6  1.5    .  .          8.04  .         .                     >   .
i6  1.75  .  .          8.02  .         .                    0.9    .

;; SECTION 1
; Lasting 42 seconds
s

; Risset
; Init Dur Amp  Pitch Delta Rise Decay
i5 0   42   5000 7.00  0.03  1   16

; Granular Effect
;  Init  Dur  Amplitude Pitch Dens Pan
i2  2    6     2500     220   200   0.5 0.1
i2  3    6     1000     440   .     0.7 0.3
i2  4    6     2500     440   .     0.5 0.9
i2  6    6     3000     660   .     0.5 0.7
i2  10   6     1000     660   300   0.5 0.3
i2  14   28    400      330   [$C3] 0.5 0.5

; Flute
; Init  Dur  Amplitude Pitch  Pressure  Breath
i1  16     2   7000     9.00    0.80      0.018     
i1  +      0.3    .     8.10    >         .    
i1  +      0.3    .     9.02    >       .       
i1  +      0.3    .     8.10    >         .       
i1  +      1    .       8.07    >        .       
i1  +      1    .       8.04    0.90       .  
i1  +      1    .       8.07    >        .     
i1  +      1    .       9.04    >        .    
i1  +      1    .       9.00    0.80        .   

; Violins
; Using the { opcode to create two loops.
; The outer loops controls amplitude.
; Init         Dur   Amp  Pitch
{ 4 OL
{ 2 IL
; Primo
i3  [8+$OL*8+$IL*2]  0.5   [1000/($OL+1)] 8.00
i3  +                 .      >            8.02
i3  +                 .      >            8.04
i3  +                 .    [8000/($OL+1)] 8.07
; Secondo
i3  [8+$OL*8+$IL*2]  0.5   [1000/($OL+1)] 8.04
i3  +                 .      >            8.07
i3  +                 .      >            9.00
i3  +                 .    [8000/($OL+1)] 8.07
}
{ 2 IL
; Primo
i3  [12+$OL*8+$IL*2]  0.5  [1000/($OL+1)] 8.04
i3  +                  .      >           8.07
i3  +                  .      >           8.09
i3  +                  .   [8000/($OL+1)] 9.00
; Secondo
i3  [12+$OL*8+$IL*2]  0.5  [1000/($OL+1)] 8.04
i3  +                  .      >           8.07
i3  +                  .      >           9.00
i3  +                  .   [8000/($OL+1)] 8.07
}
}



; Clarinet
; Init  Dur  Amp   Pitch Feed Delay
i4  24   -4   10000 9.00  0.5  0.005
i4  27.5 -2   >     8.07  0.4  .
i4  28   -4   >     9.00  0.4  .
i4  29.5 -2   >     8.09  0.4  .
i4  30   4    5000  8.07  0.5  .

; FM Pad
; Init                         Dur Amp Pitch MAmp MFreq Pan Wave
{ 8 IL
i6  [24+$IL*2]        0.5  5000 7.00  20         600      0.1   13
i6  [24.25+$IL*2]   .       >        7.07  .         .                    >    .
i6  [24.5+$IL*2]      .      >         8.00  .         .                     >   .
i6  [24.75+$IL*2]   .      >         8.02  .         .                     >   .
i6  [25+$IL*2]         .      >         8.04  .         .                      >    . 
i6  [25.25+$IL*2]   .      >         8.07  .         .                      >    .
i6  [25.5+$IL*2]     .      >          8.04  .         .                     >   .
i6  [25.75+$IL*2]   .    1000    8.02  .         .                 0.9    .
}

; Hihat
; Init Dur Amp   Freq  Rand
i9 24   3   1000  10500 200
i9 24.5  .   )    4500  >
i9 25   .   )     4500  >
i9 25.5 .   )     4500  >
i9 26   .   10000 4500  10000
i9 30   3   10000 10500 200
i9 30.5  .  )     4500  >
i9 31   .   )     4500  >
i9 31.5 .   )     4500  >
i9 32   .   1000  4500  10000

; Clarinet
; Init  Dur  Amp   Pitch Feed Delay
i4  34   -4   10000 9.04  0.5  0.005
i4  37.5 -2   >     8.07  0.4  .
i4  38   -4   >     9.04  0.4  .
i4  39.5 -2   >     9.02  0.4  .
i4  40   2    5000  9.00  0.5  .

; Hihat
; Init Dur Amp   Freq  Rand
i9 34   3   1000  10500 200
i9 34.5  .  )     4500  >
i9 35   .   )     4500  >
i9 35.5 .   )     4500  >
i9 36   .   10000 4500  10000
i9 40   3   10000 10500 200
i9 40.5  .  )     4500  >
i9 41   .   )     4500  >
i9 41.5 .   )     4500  >
i9 42   1   1000  4500  10000




;; SECTION 2
; Lasting 18 seconds
s


; Risset Arpeggio
; Init Dur Amp  Pitch        Delta Rise Decay
i5 0   16  5000 [7.00+$TRN.] 0.03  1   4

; Granular Effect
;  Init  Dur  Amplitude Pitch Dens Pan
i2  2    6     2500     220   200   0.1 0.1
i2  3    6     1000     440   .     0.3 0.3
i2  4    6     2500     440   .     0.9 0.9
i2  6    6     3000     660   .     0.5 0.5
i2  10   6     1000     660   300   0.5 0.5

; Flute
; Init  Dur  Amplitude Pitch  Pressure  Breath
i1  8     2   7000     [9.00+$TRN.]    0.90      0.018     
i1  +   0.3    .       [8.10+$TRN.]    >         .    
i1  +   0.3    .       [9.02+$TRN.]    >       .       
i1  +   0.3    .       [8.10+$TRN.]    >         .       
i1 11     1    .       [8.07+$TRN.]    >        .       
i1  +     1    .       [8.04+$TRN.]    0.95       .  
i1  +     1    .       [8.07+$TRN.]    >        .     
i1  +     1    .       [9.04+$TRN.]    >        .    
i1  +     2    .       [9.00+$TRN.]    0.80        .  
e

</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
