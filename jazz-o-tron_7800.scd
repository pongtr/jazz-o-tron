////////////////////////////////////////////////////////////////
//                                                            //
//  CPSC 431 Fall 2016                                        //
//  Team Apostrophe Final Project                             //
//  Pong Trairatvorakul, Pauli Xu, Sophia Eller               //
//                                                            //
//   __                                 _                     //
//   \ \  __ _ ________      ___       | |_ _ __ ___  _ __    //
//    \ \/ _` |_  /_  /____ / _ \ _____| __| '__/ _ \| '_ \   //
// /\_/ / (_| |/ / / /_____| (_) |_____| |_| | | (_) | | | |  //
// \___/ \__,_/___/___|     \___/       \__|_|  \___/|_| |_|  //
//                                                            //
//                    _____ ___   ___   ___                   //
//                   |___  ( _ ) / _ \ / _ \                  //
//                      / // _ \| | | | | | |                 //
//                     / /| (_) | |_| | |_| |                 //
//                    /_/  \___/ \___/ \___/                  //
//                                                            //
//                                                            //
//  Submitted December 15, 2016                               //
//                                                            //
////////////////////////////////////////////////////////////////

// INSTRUCTIONS
// 1. Evaluate every block
// 2. Play around on GUI
// 3. Enjoy!

(
// notes per octave
n = 12;
// names of notes (for human readability)
~names = ["C ", "Db", "D ", "Eb", "E ", "F ", "Gb", "G ", "Ab", "A ", "Bb", "B "];

// == Part I: The Leadsheet ====================================
// Automata system to generate leadsheet
g = (
	// key
	key: 0,     // where 0:C, 1:Db, ... , 11:B

	// tonality
	//  where \maj => maj7
	//        \min => min7
	//        \dom => dom7
	//        \hdm => half-dim7
	ton1: \maj, // curent
	ton2: \maj, // previous

	// chord scale
	scale: [0,1,2,3,4],

	// chord
	chord: [0, 4, 7, 11],

	// chord length
	length: 1,

	// initialize the pitch class and tonality states
	init: {
		|key = 0, ton = \maj|    // default vals

		var chord = switch(ton)  // chord values
		{\maj} {[0, 4, 7, 11]}
		{\min} {[0, 3, 7, 10]}
		{\dom} {[0, 4, 7, 10]}
		{\hdm} {[0, 3, 6, 10]}
		{\dim} {[0, 3, 6, 9]};

		var scaleName = switch(ton) // map tonality to possible scales
		{\maj} {[\ionian, \lydian, \majorPentatonic]}
		{\min} {[\dorian, \minorPentatonic]}
		{\dom} {[\mixolydian]}
		{\hdm} {[\locrian]}
		{\dim} {[\dimished]};

		// store vals
		g.chord = chord;
		g.scale = Scale.at(scaleName.choose).degrees;
		g.ton1 = ton;
		g.ton2 = ton;
		g.length = 1;
	},

	// increment state
	incr: {
		// Auxiliary functions:
		var getScale = {        // get new chord scales, given tonality
			// "https://www.apassion4jazz.net/jazz-chords-scales.html"
			|ton|
			var scaleName = switch(ton)
			{\maj} {[\ionian, \lydian, \majorPentatonic]}
			{\min} {[\dorian, \minorPentatonic]}
			{\dom} {[\mixolydian]}
			{\hdm} {[\locrian]}
			{\dim} {[\dimished]};
			g.scale = Scale.at(scaleName.choose).degrees;
		};
		var getChord = {        // get chord notes, given tonality
			|ton|
			var chord = switch(ton)
			{\maj} {[0, 4, 7, 11]}
			{\min} {[0, 3, 7, 10]}
			{\dom} {[0, 4, 7, 10]}
			{\hdm} {[0, 3, 6, 10]}
			{\dim} {[0, 3, 6, 9]};
			g.chord = chord;
		};

		// find new tonality
		var next; // next tonality
		case
		// maj7 can pretty much lead anywhere
		//   took dom out since we'd rather hear ii-V-I
		{g.ton1 == \maj} {
			next = [\maj, \min, \hdm].choose;
		}
		// min7 can also pretty much lead anywhere
		{g.ton1 == \min} {
			next = [\maj, \min, \dom, \hdm].choose;
		}
		// min7-dom7-maj7 sequence #idiomatic
		{g.ton1 == \dom && g.ton2 == \min} {
			next = [\maj].choose;
		}
		// hdm7-dom7-min7 sequence #idiomatic
		{g.ton1 == \dom && g.ton2 == \hdm} {
			next = [\min].choose;
		}
		// reached dom by other means (\dom is the only option left)
		//   can lead to maj, min, another dom
		{g.ton1 == \dom} {
			next = [\maj, \min, \dom].choose;
		}
		// hdm always goes to dom (and then to min) :D
		{g.ton1 == \hdm} {
			next = \dom;
		}
		{ "Input not accepted.".postln;};
		g.ton2 = g.ton1;   // move current tonality to prev
		g.ton1 = next;     // store next tonality to current
		getChord.value(next); // get chord tones
		getScale.value(next); // get scale degrees

		// find new key
		// d for how many semitones down
		case
		// if dom, then down P5 motion (or tritone sub)
		{g.ton2 == \dom} {
			d = [7,1].wchoose([0.6,0.4]);
		}
		// hdm goes down P5
		{g.ton2 == \hdm} {
			d = 7;
		}
		// else can go down m3, M3, P4, P5, m6, M6
		{ d = [3,4,5,7,8,9].choose; };
		// calculate new key and scale (to keep it in one oct)
		g.key = (g.key - d) % 12;
	}
)
)

(
// make leadsheet
~makeLS = {
	|length = 16, key0 = 0, ton0 = \maj|
	var ls = List[];
	g.init;           // intialize chord automata
	g.key = key0;     // set initial conditions
	g.ton1 = ton0;
	g.ton2 = ton0;
	length.do({       // generate chords to fill LENGTH measures
		|measure|
		var len = switch ((measure) % 4) // pick chord length
		{0} { [0.5, 1].choose }
		{1} { 1 }
		{2} { [0.5, 1].choose }
		{3} { 1 };
		var genChord = {                 // get chord based on automata
			var chord = Dictionary.new;
			chord.add(\key -> g.key);
			chord.add(\ton -> g.ton1);
			chord.add(\scale -> g.scale);
			chord.add(\chord -> g.chord);
			chord.add(\length -> len);
			g.length = len;   // store generated length
			g.incr;           // increment automata
			ls.add(chord);    // add generated chord to leadsheet
		};
		(1/len).do({genChord.value()}); // fill measure with chord(s)
	});
	ls; // return leadsheet
};
// print out leadsheet to console
~printLS = {
	|ls|
	var loc = 0;     // location in measure
	var measure = 0; // measure number
	ls.do({
		|item, i|
		if (measure % 4 == 0) {"".postln};            // newline every 4 measures
		loc = (loc + item[\length]) % 1;              // set new location
		(" " + ~names[item[\key]] + item[\ton]).post; // print chord name and tonality
		if (item[\length] == 1) { "    %   ".post };  // print % if not new chord
		measure = measure + item[\length];            // increment measure
		if (loc == 0) {" |".post;};                   // print bar lines
	});
	"".postln; // trailing newline
};

// == Part II: The Rhythm Section ====================================
// Bass
~makeBass = {
	// takes leadsheet and style
	|ls, style = \hold|

	// aux func: walking bass
	var walk = {
		|from, to, scale, length|
		var diff = to - from;      // difference between to and from
		var ret = [from];          // pitch array to return
		var scaleExt = ((scale - 12) ++ scale ++ (scale + 12)) + from; // scale walking on
		var id = scaleExt.indexIn(to); // find index of to in scaleExt
		case
		{diff <  0} { // descend
			var ids = switch(length)
			{1  } {[id + 3, id + 2, id + 1]}
			{0.5} {[id + 1]};
			ids.do({
				|item, i|
				ret.add(scaleExt[item]);
			});
		}
		{diff == 0} { // same
			var notes = switch(length)
			{1  } {[1, 0, -1]}
			{0.5} {[1, -1].choose};
			ret.add(notes + from);
		}
		{diff >  0} { // ascend
			var ids = switch(length)
			{1  } {[id - 3, id - 2, id - 1]}
			{0.5} {[id - 1]};
			ids.do({
				|item, i|
				ret.add(scaleExt[item]);
			});
		};
		ret;
	};

	var pattern = Dictionary.new;
	var m = []; // notes
	var d = []; // durations
	ls.do({     // iterate through leadsheet
		|chord, i|
		var measure = switch(style)
		{\hold} { // hold for duration of chord
			(chord[\length]/0.5).do({
				m = m ++ [chord[\key]];
				d = d ++ [1/2];
			});
		}
		{\oneFive} { // play one and five of chord
			m = m ++ chord[\key];
			d = d ++ [1/2];
			if (chord[\length] == 1) {
				m = m ++ (chord[\key] + chord[\chord][2]) % 12;
				d = d ++ [1/2];
			};
		}
		{\walk} {    // walking bass line
			if (i < (ls.size - 1)) {
				m = m ++ walk.value(chord[\key], ls[i + 1][\key], chord[\scale], chord[\length]);
				d = d ++ Array.fill(4/chord[\length], 1/4);
			} {
				m = m ++ chord[\key];
				d = d ++ 1;
			};
		};
	});
	// store notes and durs in pattern
	pattern.add(\midinotes -> m);
	pattern.add(\durs -> d);
	// return pattern
	pattern;
};


// Piano
~makePiano = {
	// takes leadsheet and style
	|ls, style = \block|

	// chord voicing (aux function)
	var voice = {
		|chord, key, ton|
		var gt = [chord[1], chord[3]] + key;  // guide tones
		var ninth = if (ton == \hdm) {0} {2}; // ninth (if not half-dim)
		var us = [chord[2], ninth] + key;     // upper structure
		gt%12 ++ (us%12 + 12);                // combine and return
	};

	var pattern = Dictionary.new;
	var m =[]; // notes
	var d =[]; // durations
	var s =[]; // sustains
	var loc = 0; // location in measure
	ls.do({      // iterate through leadsheet
		|chord, i|
		var voiced = voice.value(chord[\chord], chord[\key], chord[\ton]);
		var measure = switch(style)
		{\block} { // play for whole measure
			m = m ++ [voiced];
			d = d ++ chord[\length];
			s = s ++ chord[\length] * 1.1;
		}
		{\charleston} { // charleston rhythm
			var length = chord[\length];
			while ({length > 0}, {
				m = m ++ [voiced];
				if (loc % 1 == 0) {
					d = d ++ [(1/4) + (1/6)];
					s = s ++ [0.6/4];
				} {
					d = d ++ [(1/2) + (1/12)];
					s = s ++ [(1/2) + (1/12)];
				};
				length = length - 0.5;
				loc = loc + 0.5;
			});
		}
		{\arpeggiated} { // arpeggiate the chord
			var length = chord[\length];
			while ({length > 0}, {
				m = m ++ (chord[\chord] + chord[\key]);
				2.do({
					d = d ++ [2/12, 1/12];
				});
				s = d;
				length = length - 0.5;
			});
		}; // theoretically could add more rhythms
	});
	// store notes, durations, and sustains into pattern
	pattern.add(\midinotes -> m);
	pattern.add(\durs -> d);
	pattern.add(\sustains -> s);
	// return pattern
	pattern;
};

// Percussion
~makeDrums = {
	|measures, rounds, drumType|
	var drumPhrase, drums, kick, snare, hihat;
	// Some basic drum rhythms in jazzy 12/8
	var percussion = {
		arg nMeasures, type = 1, fill = false;
		var myfill, percussion;
		var kick, snare, hat;
		var kM, sM, hM;

		// dictionary of fills
		var fills = Dictionary.newFrom([
			\1, [[0,0,0, 0,0,0, 0,0,0, 0,0,0],
				[1,1,1, 1,1,1, 1,1,1, 1,1,1],
				[0,0,0, 0,0,0, 0,0,0, 0,0,0,]],
			\2, [[1,0,0, 1,0,0, 1,0,0, 1,0,0],
				[0,1,1, 0,1,1, 0,1,1, 0,1,1],
				[1,0,0, 1,0,0, 1,0,0, 1,0,0]]
		]);

		// hardcoded drum rhythms
		// 0 = silence, 1 = play
		// 2 = open hat
		if ((type == 1),{
			kM = [1,0,1, 0,0,0, 1,0,1, 0,0,0];
			sM = [0,0,0, 1,0,1, 0,0,0, 1,0,1];
			hM = [1,0,0, 1,0,1, 1,0,0, 1,0,1];
		});

		if ((type == 2),{
			kM = [0,0,1, 0,0,1, 0,0,1, 0,0,1];
			sM = [0,0,0, 1,0,0, 0,0,0, 1,0,0];
			hM = [1,0,0, 1,0,1, 1,0,0, 1,0,1];
		});

		if ((type == 3),{
			kM = [0,0,0, 0,0,0, 0,0,0, 0,0,0];
			sM = [0,0,0, 0,0,0, 0,1,1, 0,0,0];
			hM = [1,0,0, 1,0,1, 1,0,0, 1,0,1];
		});

		if ((type == 4),{
			kM = [0,0,0, 0,0,0, 0,0,0, 0,0,0];
			sM = [0,1,1, 0,0,0, 0,1,1, 0,0,0];
			hM = [1,0,0, 1,0,1, 1,0,0, 2,0,1];
		});

		if ((type == 5),{
			kM = [0,0,1, 0,0,0, 0,0,1, 0,0,0];
			sM = [1,1,0, 0,0,0, 1,1,0, 0,0,0];
			hM = [1,0,0, 1,0,1, 1,0,0, 2,0,1];
		});

		if ((type == 6),{
			kM = [0,0,0, 0,0,0, 0,0,1, 0,0,0];
			sM = [0,0,1, 0,1,1, 0,0,0, 1,0,0];
			hM = [1,0,0, 1,0,1, 1,0,0, 2,0,1];
		});

		// fill out nMeasures
		kick = kM;
		snare = sM;
		hat = hM;
		if ((fill),
			{
				(nMeasures-2).do({
					kick = kick++kM;
					snare = snare++sM;
					hat = hat++hM;
				});
				myfill = fills.keys.choose;
				("Fill: "+myfill).postln;
				kick = kick++fills[myfill][0];
				snare = snare++fills[myfill][1];
				hat = hat++fills[myfill][2];
			},{
				(nMeasures-1).do({
					kick = kick++kM;
					snare = snare++sM;
					hat = hat++hM;
				});
		});

		percussion = Array.with(kick,snare,hat);
	};

	var percussionDur = {
		arg in;
		var out = Array.fill(in.size,
			{arg i;
				if ((in[i] == 0),
					{Rest(1/12)},
					{1/12})});
		out;
	};
	drums = percussion.value(measures,drumType,true);
	kick = Pbind(
		\instrument, \kick2,
		\dur, Pseq(percussionDur.value(drums[0]), rounds),
		//	\att, 0.03,
		//	\rel, 0.22,
		//	\sinfreq, Pseq([30, 35, 50 , 50, 70, 70, 75, 80, 50, 70, 50, 45, 40, 35, 30],64),
		//	\glissf, 0.9,
		\amp, 0.65,
	);

	snare = Pbind(
		\instrument, "snare",
		\dur, Pseq(percussionDur.value(drums[1]), rounds),
		//	\att, 0.01,
		//	\rel, 0.1,
		//	\sinfreq, 180,
		//	\ffreq, 3000,
		\amp, 0.1,
	);

	hihat = Pbind(
		\instrument, \hihat,
		\dur, Pseq(percussionDur.value(drums[2]), rounds),
		//	\att, 0.05,
		//	\rel, 0.1,
		//	\ffreq, Pseq([1000, 600, 9000], inf),
		//	\pan, 0,
		\amp, 0.5,
	);

	Dictionary.with(*[\kick->kick,\snare->snare,\hihat->hihat]);
};

)

// == Part III: The Soloist(s) ====================================
(
//return pitch as scale degree in scale
var pitch_to_scale_degree = { |scale, pitch|
	var degree = -1;
	var i = 0;
	var size = scale.size;
	//normalize pitch to octave
	pitch = pitch % 12;
	//walk through sc ale to find pitch
	while({ (degree == (-1)) && (i < size)},
		{if (scale[i] == pitch,
			{degree = i;},
			{i = i+1}
			);
		};
	);
	//if somehow fail, return random scale degree
	if(degree == (-1),
		{degree = scale.choose}
	);
	//return
	degree;
};



//from scale (one octave) and scale degree (in any octave), get pitch
var scale_degree_to_pitch = { |scale, i|
	var size = scale.size();
	var pitch = scale[(i % size)];
	var scales_away = floor(i / size);

	//return
	pitch + (12 * scales_away);
};


//given current pitch, chord, and dist,
//return all chord degrees within dist from pitch
//For now, assume max dist is 2 octaves.
var dist_filt_chord = {arg cur_pitch, next_chord, dist;
	var pitch_adj = cur_pitch % 12;
	var chord_range = (next_chord - 24 ) ++ (next_chord - 12) ++ next_chord ++ (next_chord + 12);
	var filt_chord = chord_range.select {|chord_note| abs(chord_note - pitch_adj) < dist };
	//return
	filt_chord;
};

// Flourishes
// Dynamics - dynamic styling
// adds amp Pseq to FEATURES
var dynamics = {
	// MINAMP and MAXAMP determine amplitude range
	// Note: to play louder for lower pitch, pass minamp > maxamp
	arg features, pitches, durs, minamp=0.2, maxamp=0.6;
	var total_beats, amps;
	// Basic dynamics: louder for higher pitch
	amps = Array.fill(durs.size, {|i| if (pitches[i]==\rest, {0}, {pitches[i]})});
	amps = amps.normalize(minamp,maxamp).round(0.01);
	// Stress downbeats slightly, swing beats more heavily
	total_beats = 0;
	for (0, amps.size-1,
		{|i|
			if (((total_beats % 1) == 0), {amps[i] = amps[i]+0.05});
			if (((total_beats*12 % 3) == 2), {amps[i] = amps[i]+0.1});
			total_beats = (total_beats+durs[i]).round(1/12);
		}
	);
	// Add to features
	features[\amp] = amps;
};

// Legato - elongated play style
// adds sustain Pseq to FEATURES
var legato = {
	// To sustain longer, increase DEGREE.  To shorten, decrease below 1.
	arg features, pitches, durs, degree=1.1;
	var sustains;
	sustains = degree*durs;
	features[\sustain] = sustains;
};

// Staccato - short, sharp play style
// adds sustain Pseq to FEATURES
var staccato = {
	// Change NOTE_LEN to sustain notes longer or shorter
	arg features, pitches, durs, note_len = 1/12;
	var sustains;
	sustains = Array.fill(durs.size, {note_len});
	features[\sustain] = sustains;
};

// Change_Octave - changes octave, defaults to no change
var change_octave = {
	// Set CHANGE to change octave
	arg features, pitches, durs, change=0;
	if ((features[\octave] == nil),
		{features[\octave] = 5+change},
		{features[\octave] = features[\octave]+change});
};

// Out of Tune - play out of tune
// changes pitches in FEATURES
var out_of_tune = {
	// Set WARP_FACTOR to determine how out of tune it plays
	arg features, pitches, durs, warp_factor=0.25;
	var warps;
	warps = Array.fill(pitches.size, {100.bilinrand}).normalize(-1*warp_factor, warp_factor);
	features[\note] = Pseq(pitches+warps,1);
};

// Overarticulate - articulate every 1/12 note
// changes pitches and durations in FEATURES
var overarticulate = {
	arg features, pitches, durs;
	var new_pitches, new_durs;
	new_pitches = [];
	new_durs = [];
	for (0, durs.size-1,
		{|i|
			var n = durs[i]*12;
			new_durs = new_durs ++ Array.fill(n,{1/12});
			new_pitches = new_pitches ++ Array.fill(n,{pitches[i]});
	});
	durs.postln;
	pitches.postln;
	new_durs.postln;
	new_pitches.postln;
	features[\dur] = Pseq(new_durs,1);
	features[\note] = Pseq(new_pitches,1);
};



/*Return an initialized skill_call of a soloist.
Could have different initializations for different soloist personalities.

The skill_call has two tasks:
  1)track musical info and needs for next chunk of music
    (information needed to choose and apply skills)
  2)have collection of skills and preferences for how often the skill is used. \
    (duration, scale, and pitch skills)
    (the skills are called in this order in melody generator)
*/

/*try with:
~dur_skills.at(~dur_skills.keys.choose.postln).(~skill_call).postln;
~pitch_skills.at(~pitch_skills.keys.choose.postln).(~skill_call).postln;*/

~init_skill_call_1 = {
	var skill_call = Dictionary.new;
	skill_call.putAll(
		Dictionary[
			/*these variables vary all the time
			when generating a solo*/
			\beats -> 2,        //size of the chunk generated; 1 measure is 4 beats.
			\num_of_notes -> 8, //#notes within chunk
			\pitch -> 0,
			\scale_deg -> 0,
			\prev_pattern_pitch -> [0],
			\prev_pattern_dur -> [1],
			\target_pitch -> 4,
			\scale -> Scale.mixolydian.degrees,
			\pos_in_scale -> 10,
			\chord -> [0,2,4],
			\beats_from_last_phrase -> 0,

			/*these are mostly changed by special skills.*/
			\note_dur_default -> (1/3),
			\phrase_length -> (4 * 8), //4 beats times 8 measures
			\pitch_skill_names -> [ \repeat, \chrom_walk, \roll_move, \walk, \roll_around, \rest_start ],
			\pitch_skill_weights -> [ 0.05,  0.1,  0.1,  0.2,  0.1, 0.1 ].normalizeSum,
			\scale_skill_names -> [\regular, \sidestep],
			\scale_skill_weights -> [0.8, 0.2].normalizeSum,
			\dur_skill_names -> [\default_durs, \beat_type_mix, \syncopation, \long_note],
			\dur_skill_weights -> [0.2,0.4,0.4, 0].normalizeSum,
		];
	);

	//return skill_call
	skill_call;
};


//update a skill_call
~update_sc = {arg sc, symbol, new_val;
	sc.put(symbol, new_val);
};


/*
Skills to create duration array,
using info in skill_call dictionary. (sc).
Create durations at once for \beats (defined in skill_call).
Notice that a measure is 4 \beats.

Note for alternative structure:
Could
Have internal functions to generate durations for one beat.
Have skills that call these in mixed orders.
(currently this structure is squeezed in one skill, \beat_type_mix,
 which allows less modifiability during melody generation)*/

~dur_skills = Dictionary.new;
~dur_skills.putAll(
	Dictionary[
		//fill \beats with default durations
		\default_durs -> {|sc|
			var size = sc.at(\beats) * (1 / sc.at(\note_dur_default));
			var durations = Array.fill(size, {sc.at(\note_dur_default)});
			~update_sc.(sc, \num_of_notes, size);

			//return
			durations;
		};,
		/*
		Have internal functions to generate durations for one beat.
		mix these according to fixed weights.
		for every beat, pick n and put n even notes, or
		a two swingy eigth notes (2/12, 1/12).*/
		\beat_type_mix -> {|sc|
			var size_types = [[3,2], [5,5], [1, 1]]; //reg, fast, slow. Notes per beat.
			var type_weights = [0.8,0.1,0.1]; //favor reg speed, i.e. triples/eigths.
			var size_weights = [0.7,0.3]; //favor triples over eigths
			var durations = Array.new();
			var beats = sc.at(\beats);

			//for each beat, choose number of notes in it. Put n even notes,
			//or two swingy notes if n == 2.
			beats.do{
				var beat_size = size_types.wchoose(type_weights).wchoose(size_weights);
				var beat_durs = if (beat_size != 2,
					{Array.fill(beat_size, {1 / beat_size})},
					{[2/3, 1/3]}
				);

				durations = durations ++ beat_durs;};

			~update_sc.(sc, \num_of_notes, durations.size);

			durations;
		};,
		//one long note over whole chunk
		\long_note -> {|sc|
			var durations = Array.new();
			var beats = sc.at(\beats);
			durations = [beats];

			~update_sc.(sc, \num_of_notes, durations.size);

			durations;

		};,
		//syncopate over chunk (i.e. \beats). Assumes chunk are divisible by 2.
		\syncopation -> {|sc|
			var beats = sc.at(\beats);
			var size = 3;
			var durations = ([2,3,1] / 3 ).wrapExtend( (size * beats / 2).asInt );

			~update_sc.(sc, \num_of_notes, durations.size);

			durations;
		};
	];
);


/*Skills to modify scale in skill_call dictionary (sc)
(thus breaking away from leadsheet scale).*/
~scale_skills = Dictionary.new;
~scale_skills.putAll(
	Dictionary[
		//stay in scale
		\regular -> {|sc|
		};,
		//take scale complement set.
		\complement -> {|sc|
			var complement = Array.series(12,0,1).asSet - sc.at(\scale).asSet;

			~update_sc.(sc, \scale, complement.asArray);
		};
		//do sidestep (raise scale by a semitone)
		\sidestep -> {|sc|
			var sidestep = sc.at(\scale) + 1;

			~update_sc.(sc, \scale, sidestep.asArray);
		};
	];
);





/*
Skills to create pitch array,
using info in skill_call dictionary. (sc).
Create pitches at once for \num_of_notes, specified
in sc by a duration skill.

Some are target-note-aware.
Some are scale aware.
etc.*/
~pitch_skills = Dictionary.new;
~pitch_skills.putAll(
	Dictionary[
		//walk chromatically towards target pitch
		\chrom_walk -> {|sc|
			var size = sc.at(\num_of_notes);
			var start = sc.at(\pitch);
			var step = (sc.at(\target_pitch) - sc.at(\pitch)).sign;
			var pitches = Array.series(size, start, step);

			//return
			pitches;

		};,
		//walk in scale towards target pitch
		\walk -> {|sc|
			var size = sc.at(\num_of_notes);
			var start = sc.at(\pitch);
			var direction = (sc.at(\target_pitch) - sc.at(\pitch)).sign;
			var pitches = Array.fill(size, {0});

			//generate degrees and convert to pitches
			size.do{|i| pitches.put(i, scale_degree_to_pitch.(sc.at(\scale), i));};

			//return
			pitches;
		};,
		//with small \beats

		//a crippled leap skill.
		/*\leap -> {|sc|
			var size = sc.at(\num_of_notes);
			var start = sc.at(\pitch);
			var pos_in_scale = sc.at(\pos_in_scale);
			var target = sc.at(\target_pitch);
			var direction = (target - start).sign;
			var pitches = Array.fill(size, {0});

			//if going down, reverse scale and position in the reversed scale
			if (direction < 0,
				{pos_in_scale = pitch_to_scale_degree.(sc.at(\scale).reverse, start);});

			//generate degrees and convert to pitches
			size.do{|i| pitches.put(i, scale_degree_to_pitch.(sc.at(\scale), i*2*direction));};
			//return
			pitches;
		};,
		*/

		//roll around the current note for number of notes
		\roll_around -> {|sc|
			var size = sc.at(\num_of_notes);
			var start = sc.at(\pitch);
			var pitches = Array.fill(size, {0});

			var degrees = [-1,0,2,1].scramble.foldExtend(size.asInt);

			//convert to pitches
			size.do{|i| pitches.put(i, scale_degree_to_pitch.(sc.at(\chord), degrees[i]))};

			//return
			pitches;
		};,
		//move in a rolling pattern towards target pitch
		\roll_move -> {|sc|
			var size = sc.at(\num_of_notes);
			var roll_size = [2,3].choose;
			var start = sc.at(\pitch);
			var direction = (sc.at(\target_pitch) - sc.at(\pitch)).sign;
			var pitches = Array.fill(size, {0});
			var roll_pattern = [-1,0,2,1].scramble.keep(roll_size.asInt);
			var degrees = Array.new();

			//add pattern until it doesn't fit.
			while({size >= roll_size},
				{degrees = degrees ++ roll_pattern;
					size = size - roll_size;
				roll_pattern = roll_pattern + direction;}
			);
			//add a tail
			degrees = degrees ++ roll_pattern.scramble.keep(size.asInt);
			//convert to pitches
			degrees.size.do{|i| pitches.put(i, scale_degree_to_pitch.(sc.at(\chord), degrees[i]))};

			//return
			pitches;
		};,
		//repeat current note.
		\repeat -> {|sc|
			var size = sc.at(\num_of_notes);
			var start = sc.at(\pitch);
			var pitches = Array.fill(size, {start});

			//return
			pitches;
		};,
		//call another pitch skill. convert 1st note to a rest.
		\rest_start -> {|sc|
			var pitches = ~pitch_skills.at(~pitch_skills.keys.choose).(sc);
			pitches.put(0, \rest);

			//return
			pitches;
		};
	];
);


/*make a soloist from
  lead sheet, skill_call dictionary, skills, and #rounds going through the lead sheet.
  Return dictionary including \pitches (array) and \durations (array)*/
~makeLeadv1 = {arg l_sheet, skill_call, dur_skills, pitch_skills, scale_skills, rounds;
	/*track what is generated.
	  store chunks for each half-measure.
	  If chunk is longer than half-measure,
	  after first, store '-' */
	var all_pitch_chunks = Array.new();
	var all_duration_chunks = Array.new();
	var pitch_skill_chunks = Array.new();
	var dur_skill_chunks = Array.new();
	var scale_chunks = Array.new();
	var chord_chunks = Array.new();
	var features = Dictionary.new();

	//outputs
	var all_pitches = Array.new();
	var all_durations = Array.new();
	//repeat lead sheet according to rounds.
	l_sheet = l_sheet.wrapExtend(rounds * l_sheet.size);

	//for each chord in lead sheet
	l_sheet.do{ |chord_dict, i|
		var chunk_pitches = Array.new();
		var chunk_durations = Array.new();
		var pitch_skill_used;
		var dur_skill_used;
		var scale_skill_used;
		var last_note;
		var new_target_pitch;
		var next_chord_filt;
		var next_chord_dict = l_sheet[i+1];
		var next_chord;
		var first_note; // try out
		var first_note_index;


		// pick starting note for the very first run.
		if (i == 0) {
			~update_sc.(skill_call, \pitch, (chord_dict[\chord] + chord_dict[\key]).choose);
		};

		//at the end of lead_sheet, choose next chord as the first chord of lead sheet.
		if (next_chord_dict == nil,
			{next_chord_dict = l_sheet[0];}
		);
		next_chord = next_chord_dict.at(\chord) + next_chord_dict.at(\key);

		//READ L_SHEET

		//update skill_call according to current lead_sheet position. (chord, scale, etc.)
		~update_sc.(skill_call, \chord, chord_dict.at(\chord));
		~update_sc.(skill_call, \scale, chord_dict.at(\scale) + chord_dict.at(\key));
		~update_sc.(skill_call, \beats, (chord_dict.at(\length) / 0.25));
		~update_sc.(skill_call, \beats_from_last_phrase, (skill_call.at(\beats_from_last_phrase) + skill_call.at(\beats)));

		//DUR SKILLS

		//create durations and pitches according for this length of measures
		//choose duration skill. Could have skills to update weights.
		dur_skill_used = skill_call.at(\dur_skill_names).wchoose(skill_call.at(\dur_skill_weights));
		//check if at end of phrase
		if (skill_call.at(\beats_from_last_phrase) >= (skill_call.at(\phrase_length))) {
			dur_skill_used = \long_note;
			~update_sc.(skill_call, \beats_from_last_phrase, 0);
			~update_sc.(skill_call, \phrase_length, 4 * [2, 4,8].wchoose([0.1, 0.2,0.7]));
		};
		//create durations
		chunk_durations = dur_skills.at(dur_skill_used).(skill_call);

		//SCALE SKILLS

		//possibly change scale. Not tracked right now.
		scale_skill_used = skill_call.at(\scale_skill_names).wchoose(skill_call.at(\scale_skill_weights));
		//scale_skill_used = \one_note;
		scale_skills.at(scale_skill_used).(skill_call);

		//PITCH SKILLS

		pitch_skill_used = skill_call.at(\pitch_skill_names).wchoose(skill_call.at(\pitch_skill_weights));
		chunk_pitches = pitch_skills.at(pitch_skill_used).(skill_call);

		//UPDATE SC ON WHAT JUST HAPPENED

		//update skill_call according to newly generated stuff
		//don't update prev_pattern_pitch if end in rest. currently only possible with \rest_start & \long_note
		if (chunk_pitches.last.isInteger,
			{~update_sc.(skill_call, \prev_pattern_pitch, chunk_pitches);}
		);
		~update_sc.(skill_call, \prev_pattern_dur, chunk_durations);

		//update current position
		last_note = chunk_pitches.last;
		if (last_note.isInteger == false,
			{last_note = skill_call.at(\prev_pattern_pitch).last}
		);
		~update_sc.(skill_call, \pitch, skill_call[\target_pitch]);
		~update_sc.(skill_call, \scale_deg, pitch_to_scale_degree.(skill_call.at(\scale), last_note));

		//update target note (seeder task)
		next_chord_filt = dist_filt_chord.(last_note, next_chord, [12,16,20].choose);
		new_target_pitch = next_chord_filt.choose;
		~update_sc.(skill_call, \target_pitch, new_target_pitch);

		//STORE OUTPUT

		//store in output
		all_pitches = all_pitches ++ chunk_pitches;
		all_durations = all_durations ++ chunk_durations;

		//store output per each half_measure.
		(skill_call.at(\beats) / 2 ).do{ |k|
			if ((k < 1),
				{
					all_pitch_chunks = all_pitch_chunks ++ [chunk_pitches];
					all_duration_chunks = all_duration_chunks ++ [chunk_durations];
					pitch_skill_chunks = pitch_skill_chunks ++ [pitch_skill_used];
					dur_skill_chunks = dur_skill_chunks ++ [dur_skill_used];
					scale_chunks = scale_chunks ++ [skill_call.at(\scale)];
					chord_chunks = chord_chunks ++ [skill_call.at(\chord)];
				};,
				{
					all_pitch_chunks = all_pitch_chunks ++ ['-'];
					all_duration_chunks = all_duration_chunks ++ ['-'];
					pitch_skill_chunks = pitch_skill_chunks ++ ['-'];
					dur_skill_chunks = dur_skill_chunks ++ ['-'];
					scale_chunks = scale_chunks ++ ['-'];
					chord_chunks = chord_chunks ++ ['-'];
				};
			);
		};
	};

	//normalize durations to treat measure as 1, instead of beat as 1.
	all_durations = all_durations / 4;

	// flourish
	dynamics.value(features,all_pitches,all_durations);
	//staccato.value(features,all_pitches,all_durations, 1/20);
	if (features[\sustain].isNil) {
		features[\sustain] = all_durations;
	};

	//return
	Dictionary[
		\pitches -> all_pitches, \durations -> all_durations, \sustains -> features[\sustain],
		\pitch_skill_chunks -> pitch_skill_chunks, \dur_skill_chunks -> dur_skill_chunks,
		\pitch_chunks -> all_pitch_chunks, \duration_chunks -> all_duration_chunks,
		\scale_chunks -> scale_chunks, \chord_chunks -> chord_chunks,
		\amp->features[\amp]
	];
};

// Same rhythm. Offers some kind of harmony
~harmonize = {
	|ls, melody|

	var harmonyNotes = Array.new(melody[\pitches].size); // new line
	var harmonyDurs  = melody[\durations]; // same durations as track1
	var octSize = 12; // all scales divided into 12 semitones in this case

	var loc = 0.0;
	var lsIndex = 0; // index in leadsheet
	var lsSize = ls.size;
	melody[\pitches] = melody[\pitches].keep(melody[\durations].size);
	melody[\pitches].do({
		| note1, i |
		var dur = melody[\durations][i];
		var chord = ls[lsIndex % lsSize];
		//var bassNote = bass[0][bassIndex]; // Get bass note
		//var chordNotes = ~chord.value(bassNote); // Build chord tones
		var chordNotes = (chord[\chord] + chord[\key]) % octSize;
		var note2Arr = [  // Possible intervals:
			note1 - 4,    // maj 3
			note1 - 3,    // min 3
			note1 - 9,    // maj 6
			note1 - 8,    // min 6
			note1 - 7,    // per 5
			note1 - 5     // per 4
		];
		var probs = Array.fill(note2Arr.size, 1);
		chordNotes = chordNotes % octSize; // scale chord tones to be indexable
		// Reassign weights
		note2Arr.do({
			|note2, j|

			var inChord;
			var index = ((chord[\scale] + chord[\key]) % octSize).indexOf(note2 % octSize);
			if (index.isNil) {
				// Note not in scale => 0 probability
				probs.put(j, probs[j] * 0.1);
			};

			// Test if note is in chord
			inChord = chordNotes.indexOf(note2 % octSize);
			if (inChord.isNil) {} {
				// Note in chord => double relative probability
				probs.put(j, probs[j] * 2);
			};
		});

		// Ensure that last note forms tonic chord
		if (i == (melody[\pitches].size - 1)) {
			probs[0] = 0;
			probs[1] = 0;
			probs[4] = 0;
		};
		// Normalize probability array
		probs = probs.normalizeSum;

		// Choose note and store
		harmonyNotes.add(note2Arr.wchoose(probs));

		// Advance bass note
		loc = loc + dur;
		if (loc > chord[\length]) {
			loc = 0;
			lsIndex = lsIndex + 1;
		};

	});

	// return values
	Dictionary[\pitches->harmonyNotes, \durations->harmonyDurs, \sustains->melody[\sustains], \amp->(melody[\amp] * 0.5)]
};
)

// == Part IV: Play ====================================
(
~play = {
	~leads.do({
		|lead, i|
		Pbind(
			\instrument, \rhodey_sc,
			\sustain, Pseq(lead[\sustains], 1),
			\dur, Pseq(lead[\durations], 1),
			\octave, 5,
			\amp, Pseq(lead[\amp],1),
			\note, Pseq(lead[\pitches], 1)
		).play;
	});

	Pbind(
		\instrument, \rhodey_sc,
		\sustain, Pseq(~piano[\sustains],~rounds),
		\dur, Pseq(~piano[\durs],~rounds),
		\octave, 4,
		\amp, 0.2,
		\note, Pseq(~piano[\midinotes], ~rounds)
	).play;

	Pbind(
		\instrument, \bass,
		\sustain, Pseq(~bass[\durs],~rounds) * 0.8,
		\dur, Pseq(~bass[\durs],~rounds),
		\octave, 4,
		\amp, 0.3,
		\note, Pseq(~bass[\midinotes], ~rounds)
	).play;


	~drums[\kick].play;
	~drums[\snare].play;
	~drums[\hihat].play;
};
)

// == Part V: GUI Fun ====================================
(
// elements
var wd,tempoSlider, measuresSlider, roundsSlider, keySlider,
bassPattern, pianoPattern, drumPattern, harmonizeBox,
playButton, genButton, // gen score and play buttons
p1, p2, p3, p4, p5;    // preset buttons

var harmonize = false;
wd = GUI.window.new( "Jazz-o-tron 7800", Rect( 128, 64, 400, 700 ));

// tonality of first chord
~ton0 = \maj;

// determine tempo
tempoSlider = EZSlider(
	wd,        // parent
	Rect(20,20,360,40),    // bounds
	"Tempo",  // label
	ControlSpec(10/60,70/60,'lin',1/60),     // controlSpec
	{ |val| ~tempo = val.value}, // action
	40/60,
	true,
	100
);

// number of measures
measuresSlider = EZSlider(
	wd,        // parent
	Rect(20,80,360,40),    // bounds
	"Measures",  // label
	ControlSpec(4,256,'lin',4),     // controlSpec
	{ |val| ~measures = val.value }, // action
	32,
	true,
	100
);

// number of rounds (repeats)
roundsSlider = EZSlider(
	wd,        // parent
	Rect(20,140,360,40),    // bounds
	"Rounds",  // label
	ControlSpec(1,10,'lin',1),     // controlSpec
	{ |val| ~rounds = val.value }, // action
	2,
	true,
	100
);

// key
keySlider = EZSlider(
	wd,        // parent
	Rect(20,200,360,40),    // bounds
	"Key",  // label
	ControlSpec(0,11,'lin',1),     // controlSpec
	{ |val| ~key0 = val.value }, // action
	0,
	true,
	100
);

StaticText.new(wd,Rect(20,260,200,40)).string_("Bass Pattern");
~bassPattern = \walk;
bassPattern = PopUpMenu(wd, Rect(200,260,160, 40));
bassPattern.items = [\walk, \hold, \oneFive];
bassPattern.action = {|menu| ~bassPattern = menu.item};

StaticText.new(wd,Rect(20,320,200,40)).string_("Piano Pattern");
~pianoPattern = \charleston;
pianoPattern = PopUpMenu(wd, Rect(200,320,160, 40));
pianoPattern.items = [\charleston, \block, \arpeggiated];
pianoPattern.action = {|menu| ~pianoPattern = menu.item};

StaticText.new(wd,Rect(20,380,200,40)).string_("Drum Pattern");
~drumPattern = 1;
drumPattern = PopUpMenu(wd, Rect(200,380,160, 40));
drumPattern.items = [1,2,3,4,5,6];
drumPattern.action = {|menu| ~drumPattern = menu.item};

StaticText.new(wd,Rect(20,440,200,40)).string_("Harmonize Lead");
harmonize = false;
harmonizeBox = CheckBox(wd, Rect(200,440,160, 40));
harmonizeBox.action = {|val| harmonize = val.value};

~nLeads = 1;  // number of leads

// Generate score button
genButton = Button(wd, Rect(20, 540, 360, 40))
.states_([["Generate Score", Color.black]])
.action_({
	// make the leadsheet & print
	~ls = ~makeLS.value(~measures.asInt, ~key0.asInt, ~ton0);
	~printLS.value(~ls);


	// make piano part based on leadsheet
	// \block, \charleston, \arpeggiated
	~piano = ~makePiano.value(~ls, ~pianoPattern);

	// make bass part based on leadsheet
	// \hold, \oneFive, \walk
	~bass  = ~makeBass.value(~ls, ~bassPattern);

	// make drums based on length. Pick random pattern
	~drums = ~makeDrums.value(8, ~measures*~rounds/8, ~drumPattern);

	// make lead part(s)
	~leads = [];  // can potentially have multiple leads
	~nLeads.do({  // make lead part(s)
		~leads = ~leads.add(~makeLeadv1.(~ls, ~init_skill_call_1.(), ~dur_skills, ~pitch_skills, ~scale_skills, ~rounds.asInt));
	});
	// harmonize lead part
	if (harmonize && (~leads.size > 0)) {
		~leads = ~leads.add(~harmonize.value(~ls, ~leads[0]));
	};

});

StaticText.new(wd,Rect(20,500,200,40)).string_("Presets");
// preset 1
p1 = Button(wd, Rect(120, 500, 40, 30))
.states_([["P1"]])
.action_({
	tempoSlider.value = 20/60;
	~tempo = 20/60;
	~nLeads = 0;
	harmonizeBox.value = false;
	harmonize = false;
	~key0 = rand(11);
	keySlider.value = ~key0;
	~drumPattern = rrand(1,6);
	drumPattern.value = ~drumPattern;
});
p2 = Button(wd, Rect(170, 500, 40, 30))
.states_([["P2"]])
.action_({
	tempoSlider.value = 40/60;
	~tempo = 40/60;
	~nLeads = 0;
	harmonizeBox.value = false;
	harmonize = false;
	~key0 = rand(11);
	keySlider.value = ~key0;
	~drumPattern = rrand(1,6);
	drumPattern.value = ~drumPattern;
});
p3 = Button(wd, Rect(220, 500, 40, 30))
.states_([["P3"]])
.action_({
	tempoSlider.value = 50/60;
	~tempo = 50/60;
	~nLeads = 1;
	harmonizeBox.value = false;
	harmonize = false;
	~key0 = rand(11);
	keySlider.value = ~key0;
	~drumPattern = rrand(1,6);
	drumPattern.value = ~drumPattern;
});
p4 = Button(wd, Rect(270, 500, 40, 30))
.states_([["P4"]])
.action_({
	tempoSlider.value = 20/60;
	~tempo = 20/60;
	~nLeads = 1;
	harmonizeBox.value = false;
	harmonize = false;
	~key0 = rand(11);
	keySlider.value = ~key0;
	~drumPattern = rrand(1,6);
	drumPattern.value = ~drumPattern;
});
p5 = Button(wd, Rect(320, 500, 40, 30))
.states_([["P5"]])
.action_({
	tempoSlider.value = 20/60;
	~tempo = 20/60;
	~nLeads = 1;
	harmonizeBox.value = true;
	harmonize = true;
	~key0 = rand(11);
	keySlider.value = ~key0;
	~drumPattern = rrand(1,6);
	drumPattern.value = ~drumPattern;
});

playButton = Button(wd, Rect(20, 600, 360, 80))
.states_([["Play Score"]])
.action_({
	TempoClock.default.tempo = ~tempo.asFloat;
	~play.value();
});
wd.front;
)

// == Part VI: Synthdefs ====================================
(
// Bass
//     from http://sccode.org/1-4VI
SynthDef(\wobble, { arg out=0, amp=0.1, gate=1, pan=0, spread=0.8, freq=200, doneAction=2;
	var wave = {
		|freq|
		var sig, sig1, sig2, sig3;
		sig1 = LFSaw.ar(freq * 1 + (0.04 * [1,-1]));
		sig2 = LFSaw.ar(freq * 0.99 );
		sig3 = LFSaw.ar(freq * 1 );
		sig = sig1 + sig2 + sig3;
		sig = (sig*50).tanh;
		sig = sig * EnvGen.ar(\adsr.kr(Env.adsr(0.05,0.1,0.8,0.1)),gate,doneAction:doneAction);
		sig = Splay.ar(sig, spread, amp, pan);
	};
	var sig = wave.value(freq) + wave.value(0.5 * freq);
	Out.ar(out, LPF.ar(sig,freq*6));
}).add;

// Bass
//   from http://sccode.org/1-52Z
SynthDef(\acid, {
    var snd;
    snd = Pulse.ar(\freq.kr(440), 0.45);
    snd = RLPF.ar(snd, EnvGen.ar(Env([\ffreq.kr(3000), 1000, 100], [0.08, 0.4], \exp)), 0.21);
    snd = snd + (snd + 0.2 * 3).atan * 0.5;
    snd = snd * Env.adsr(0.001, 0.01, 0.7, 0.05).kr(2, \gate.kr(1));
    snd = Pan2.ar(snd, \pan.kr(0), \amp.kr(0.1));
    Out.ar(\out.kr, snd);
}).add;

// from "http://sccode.org/1-4E"
// sounds more like a trumpet/horn after the failure and cheesyness of the stk sax
SynthDef(\sax, { |out, freq=440, amp=0.1, gate=1|
	var num = 16;
	var harms = Array.series(num, 1, 1) * Array.exprand(num, 0.995, 1.001);
	var snd = SinOsc.ar(freq * SinOsc.kr(Rand(2.0,5.0),0,Rand(0.001, 0.01),1) * harms, mul:Array.geom(num, 1, 0.63));
	snd = Splay.ar(snd);
	snd = BBandPass.ar(snd, freq * XLine.kr(0.1,4,0.01), 2);
	snd = snd * amp * EnvGen.ar(Env.adsr(0.001, 0.2, 0.7, 0.2), gate, doneAction:2);
	Out.ar(out, snd!2);
}).add;

// should be more like a gated synth, but this one gives the rhythmic element
// remember to pass the bps from the language tempo!
SynthDef(\lead, { |out, freq=440, amp=0.1, gate=1, bps=2|
    var snd;
    var seq = Demand.kr(Impulse.kr(bps*4), 0, Dseq(freq*[1,3,2], inf)).lag(0.01);
    snd = LFSaw.ar(freq*{rrand(0.995, 1.005)}!4);
    snd = Splay.ar(snd);
    snd = MoogFF.ar(snd, seq, 0.5);
    snd = snd * EnvGen.ar(Env.asr(0.01,1,0.01), gate, doneAction:2);
    OffsetOut.ar(out, snd * amp);
}).add;

// yep, an organ with a sub bass tone :D
SynthDef(\organ, { |out, freq=440, amp=0.1, gate=1|
    var snd;
    snd = Splay.ar(SinOsc.ar(freq*Array.geom(4,1,2), mul:1/4));
    snd = snd + SinOsc.ar(freq/2, mul:0.4)!2;
    snd = snd * EnvGen.ar(Env.asr(0.001,1,0.01), gate, doneAction:2);
    OffsetOut.ar(out, snd * amp);
}).add;

// Kalimba
//     from http://sccode.org/1-51l
SynthDef(\kalimba, {
    |out = 0, freq = 440, amp = 0.1, mix = 0.1|
    var snd;
    // Basic tone is a SinOsc
    snd = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.005, Rand(2.5, 3.5), 1, -8), doneAction: 2);
    // The "clicking" sounds are modeled with a bank of resonators excited by enveloped pink noise
    snd = (snd * (1 - mix)) + (DynKlank.ar(`[
        // the resonant frequencies are randomized a little to add variation
        // there are two high resonant freqs and one quiet "bass" freq to give it some depth
        [240*ExpRand(0.9, 1.1), 2020*ExpRand(0.9, 1.1), 3151*ExpRand(0.9, 1.1)],
        [-7, 0, 3].dbamp,
        [0.8, 0.05, 0.07]
    ], PinkNoise.ar * EnvGen.ar(Env.perc(0.001, 0.01))) * mix);
    Out.ar(out, Pan2.ar(snd, 0, amp));
}).add;

// String synth from:
// "http://new-supercollider-mailing-lists-forums-use-these.2681727
//   .n2.nabble.com/guitar-synthdef-td7598199.html"
SynthDef(\string, {arg out=0, freq=440, pan=0, sustain=0.5, amp=0.3;
	var pluck, period, string;
	pluck = PinkNoise.ar(Decay.kr(Impulse.kr(0.005), 0.05));
	period = freq.reciprocal;
	string = CombL.ar(pluck, period, period, sustain*6);
	string = LeakDC.ar(LPF.ar(Pan2.ar(string, pan), 12000)) * amp;
	DetectSilence.ar(string, doneAction:2);
	Out.ar(out, string)
}).add;

// Mario
//     from http://sccode.org/1-11N
SynthDef(\mario, { |out, amp=0.3, freq=440, dur=0.1|
	var snd;
	snd = VarSaw.ar(freq)!2;
	snd = snd * EnvGen.ar(Env.linen(0.001, dur/2, 0.03), doneAction:2);
	OffsetOut.ar(out, snd*amp);
}).add;

// Rhodes Synth
//     from http://sccode.org/1-522
SynthDef(\rhodey_sc, {
    |
    // standard meanings
    out = 0, freq = 440, gate = 1, pan = 0, amp = 0.1,
    // all of these range from 0 to 1
    vel = 0.8, modIndex = 0.2, mix = 0.2, lfoSpeed = 0.4, lfoDepth = 0.1
    |
    var env1, env2, env3, env4;
    var osc1, osc2, osc3, osc4, snd;

    lfoSpeed = lfoSpeed * 12;

    freq = freq * 2;

    env1 = EnvGen.ar(Env.adsr(0.001, 1.25, 0.0, 0.04, curve: \lin));
    env2 = EnvGen.ar(Env.adsr(0.001, 1.00, 0.0, 0.04, curve: \lin));
    env3 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));
    env4 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));

    osc4 = SinOsc.ar(freq * 0.5) * 2pi * 2 * 0.535887 * modIndex * env4 * vel;
    osc3 = SinOsc.ar(freq, osc4) * env3 * vel;
    osc2 = SinOsc.ar(freq * 15) * 2pi * 0.108819 * env2 * vel;
    osc1 = SinOsc.ar(freq, osc2) * env1 * vel;
    snd = Mix((osc3 * (1 - mix)) + (osc1 * mix));
    snd = snd * (SinOsc.ar(lfoSpeed) * lfoDepth + 1);

    // using the doneAction: 2 on the other envs can create clicks (bc of the linear curve maybe?)
    snd = snd * EnvGen.ar(Env.asr(0, 1, 0.1), gate, doneAction: 2);
    snd = Pan2.ar(snd, pan, amp);

    Out.ar(out, snd);
}).add;

// from "https://github.com/brunoruviaro/SynthDefs-for-Patterns/blob/master/flute.scd"
SynthDef(\flute, { arg scl = 0.2, freq = 440, ipress = 0.9, ibreath = 0.09, ifeedbk1 = 0.4, ifeedbk2 = 0.4, dur = 1, gate = 1, amp = 2;

	var kenv1, kenv2, kenvibr, kvibr, sr, cr, block;
	var poly, signalOut, ifqc;
	var aflow1, asum1, asum2, afqc, atemp1, ax, apoly, asum3, avalue, atemp2, aflute1;
	var fdbckArray;

	sr = SampleRate.ir;
	cr = ControlRate.ir;
	block = cr.reciprocal;

	ifqc = freq;

	// noise envelope
	kenv1 = EnvGen.kr(Env.new(
		[ 0.0, 1.1 * ipress, ipress, ipress, 0.0 ], [ 0.06, 0.2, dur - 0.46, 0.2 ], 'linear' )
	);
	// overall envelope
	kenv2 = EnvGen.kr(Env.new(
		[ 0.0, amp, amp, 0.0 ], [ 0.1, dur - 0.02, 0.1 ], 'linear' ), doneAction: 2
	);
	// vibrato envelope
	kenvibr = EnvGen.kr(Env.new( [ 0.0, 0.0, 1, 1, 0.0 ], [ 0.5, 0.5, dur - 1.5, 0.5 ], 'linear') );

	// create air flow and vibrato
	aflow1 = LFClipNoise.ar( sr, kenv1 );
	kvibr = SinOsc.ar( 5, 0, 0.01 * kenvibr );

	asum1 = ( ibreath * aflow1 ) + kenv1 + kvibr;
	afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;

	fdbckArray = LocalIn.ar( 1 );

	aflute1 = fdbckArray;
	asum2 = asum1 + ( aflute1 * ifeedbk1 );

	//ax = DelayL.ar( asum2, ifqc.reciprocal * 0.5, afqc * 0.5 );
	ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );

	apoly = ax - ( ax.cubed );
	asum3 = apoly + ( aflute1 * ifeedbk2 );
	avalue = LPF.ar( asum3, 2000 );

	aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

	fdbckArray = [ aflute1 ];

	LocalOut.ar( fdbckArray );

	signalOut = avalue;

	OffsetOut.ar( 0, [ signalOut * kenv2, signalOut * kenv2 ] );

}).add;

//"http://sccode.org/1-4YY%0Ahttp://sccode.org/1-4YY"
SynthDef(\bass, { |outbus, midinote = 42, amp = 0.5|
  var freq = midinote.midicps;
  var subfreq = freq / 2;

  // Envelopes
  var subenv = EnvGen.kr(Env.perc(0, 1), doneAction:2);
  var env = EnvGen.kr(Env.perc(0, 0.5));

  // Component synthesis
  var pluck = Pluck.ar(PinkNoise.ar, 1, 0.2, subfreq.reciprocal) * subenv * 2;
  var tri = VarSaw.ar(freq) * env;
  var sin = SinOsc.ar(freq) * env;
  var sub = (SinOsc.ar([subfreq, subfreq - 2, subfreq + 2]).sum * subenv).tanh;
  var click = RLPF.ar(Impulse.ar(0), [2000, 8000], 1).sum * 1000;

  // Initial signal
  var sig = pluck + tri + sub + click;

  // Resonant LPFs
  sig = RLPF.ar(sig, XLine.ar(freq * 100, freq * 10, 0.15));
  sig = sig + (MoogFF.ar(sig, freq * 20, 2.5) * 0.1);

  // EQ resulting signal
  sig = BPeakEQ.ar(sig, 400, 0.5, -9);
  sig = BPeakEQ.ar(sig, 2000, 0.5, 6);
  sig = BHiShelf.ar(sig, 8000, 1, 3);
  sig = BPeakEQ.ar(sig, 200, 1, 3);

  // Apply another envelope to dampen a bit more
  sig = sig * XLine.kr(1, 0.6, 0.1);

  // Tanh distortion / limiting
  sig = (sig * 1).tanh;

  // Another round of signal coloring, using another RLPF
  // and sine components
  sig = sig + RLPF.ar(sig, XLine.ar(freq * 100, freq * 10, 0.15)) + sin + sub;

  // Another round of tanh distortion / limiting
  sig = (sig / 2.3).tanh;

  // Another resonant LPF
  sig = MoogFF.ar(sig, XLine.ar(freq*150, freq*30, 0.1), 0.1);

	Out.ar(outbus, (amp*sig)!2);
}).add;

SynthDef(\cowbell, {
    | out=0, amp=0.3, gate=1, fund_freq=540, pan=0.0 |
    var sig, env;

    sig = Pulse.ar( fund_freq * [ 1, 1.5085 ], [ 0.565, 0.445 ], [ 0.4, 0.6 ] ).distort;
    env = EnvGen.ar(
            Env(
                [ 0, 0.05, 1, 0.1, 0 ], [ 0.003, 0.002, 0.05, 0.5 ], [2, -4, -4, -4]
            ),
        gate: gate,
        timeScale: [ 1.0, 1.5 ],
        doneAction: 2
        );
    sig = Mix( sig * env );
    sig = BPF.ar( sig, fund_freq * 2, 1.808 );

    Out.ar( out, Pan2.ar( sig, pan, amp ) );
}).add;


//"http://sccode.org/1-523"

SynthDef(\kick2, {
    |out = 0, pan = 0, amp = 0.3|
    var body, bodyFreq, bodyAmp;
    var pop, popFreq, popAmp;
    var click, clickAmp;
    var snd;

    // body starts midrange, quickly drops down to low freqs, and trails off
    bodyFreq = EnvGen.ar(Env([261, 120, 51], [0.035, 0.08], curve: \exp));
    bodyAmp = EnvGen.ar(Env.linen(0.005, 0.1, 0.3), doneAction: 2);
    body = SinOsc.ar(bodyFreq) * bodyAmp;
    // pop sweeps over the midrange
    popFreq = XLine.kr(750, 261, 0.02);
    popAmp = EnvGen.ar(Env.linen(0.001, 0.02, 0.001)) * 0.15;
    pop = SinOsc.ar(popFreq) * popAmp;
    // click is spectrally rich, covering the high-freq range
    // you can use Formant, FM, noise, whatever
    clickAmp = EnvGen.ar(Env.perc(0.001, 0.01)) * 0.15;
    click = LPF.ar(Formant.ar(910, 4760, 2110), 3140) * clickAmp;

    snd = body + pop + click;
    snd = snd.tanh;

    Out.ar(out, Pan2.ar(snd, pan, amp));
}).add;

SynthDef(\snare2, {
    |out = 0, pan = 0, amp = 0.3|
    var pop, popAmp, popFreq;
    var noise, noiseAmp;
    var snd;

    // pop makes a click coming from very high frequencies
    // slowing down a little and stopping in mid-to-low
    popFreq = EnvGen.ar(Env([3261, 410, 160], [0.005, 0.01], curve: \exp));
    popAmp = EnvGen.ar(Env.perc(0.001, 0.11)) * 0.7;
    pop = SinOsc.ar(popFreq) * popAmp;
    // bandpass-filtered white noise
    noiseAmp = EnvGen.ar(Env.perc(0.001, 0.15), doneAction: 2);
    noise = BPF.ar(WhiteNoise.ar, 810, 1.6) * noiseAmp;

    snd = (pop + noise) * 1.3;

    Out.ar(out, Pan2.ar(snd, pan, amp));
}).add;

SynthDef(\hihat2, {
    |out = 0, pan = 0, amp = 0.3|
    var click, clickAmp;
    var noise, noiseAmp;
    var snd;

    // noise -> resonance -> expodec envelope
    noiseAmp = EnvGen.ar(Env.perc(0.001, 0.3, curve: -8), doneAction: 2);
    noise = Mix(BPF.ar(ClipNoise.ar, [4010, 4151], [0.15, 0.56], [1.0, 0.6])) * 0.7 * noiseAmp;

    snd = noise;

    Out.ar(out, Pan2.ar(snd, pan, amp));
}).add;

// adapted from a post by Neil Cosgrove (other three are original)
SynthDef(\clap, {
    |out = 0, amp = 0.5, pan = 0, dur = 1|
    var env1, env2, snd, noise1, noise2;

    // noise 1 - 4 short repeats
    env1 = EnvGen.ar(
        Env.new(
            [0, 1, 0, 0.9, 0, 0.7, 0, 0.5, 0],
            [0.001, 0.009, 0, 0.008, 0, 0.01, 0, 0.03],
            [0, -3, 0, -3, 0, -3, 0, -4]
        )
    );

    noise1 = WhiteNoise.ar(env1);
    noise1 = HPF.ar(noise1, 600);
    noise1 = LPF.ar(noise1, XLine.kr(7200, 4000, 0.03));
    noise1 = BPF.ar(noise1, 1620, 3);

    // noise 2 - 1 longer single
    env2 = EnvGen.ar(Env.new([0, 1, 0], [0.02, 0.18], [0, -4]), doneAction:2);

    noise2 = WhiteNoise.ar(env2);
    noise2 = HPF.ar(noise2, 1000);
    noise2 = LPF.ar(noise2, 7600);
    noise2 = BPF.ar(noise2, 1230, 0.7, 0.7);

    snd = noise1 + noise2;
    snd = snd * 2;
    snd = snd.softclip;

    Out.ar(out, Pan2.ar(snd,pan,amp));
}).add;



//"http://sccode.org/1-551"

// Basic drum kit

SynthDef(\hihat, {arg out = 0, amp = 0.5, att = 0.01, rel = 0.2, ffreq = 6000, pan = 0;
	var env, snd;
	env = Env.perc(att, rel, amp).kr(doneAction: 2);
	snd = WhiteNoise.ar;
	snd = HPF.ar(in: snd, freq: ffreq, mul: env);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef(\snare, {arg out = 0, amp = 0.1, sinfreq = 180, att = 0.01, rel = 0.2, ffreq = 2000, pan = 0;
	var env, snd1, snd2, sum;
	env = Env.perc(att, rel, amp).kr(doneAction: 2);
	snd1 = HPF.ar(
		in: WhiteNoise.ar,
		freq: ffreq,
		mul: env
	);
	snd2 = SinOsc.ar(freq: sinfreq, mul: env);
	sum = snd1 + snd2;
	Out.ar(out, Pan2.ar(sum, pan));
}).add;

SynthDef(\kick, {arg out = 0, amp = 0.5, sinfreq = 80, glissf = 0.9, att = 0.01, rel = 0.45, pan = 0;
	var env, snd, ramp;
	env = Env.perc(att, rel, amp).kr(doneAction: 2);
	ramp = XLine.kr(
		start: sinfreq,
		end: sinfreq * glissf,
		dur: rel
	);
	snd = SinOsc.ar(freq: ramp, mul: env);
	snd = Pan2.ar(snd, pan);
	Out.ar(out, snd);
}).add;

// Basic saw synth for chords and bass
SynthDef(\sawSynth, { arg freq = 440, amp = 0.1, att = 0.1, rel = 2, lofreq = 1000, hifreq = 3000;
    var env, snd;
    env = Env.perc(
		attackTime: att,
		releaseTime: rel,
		level: amp
	).kr(doneAction: 2);
    snd = Saw.ar(freq: freq * [0.99, 1, 1.001, 1.008], mul: env);
	snd = LPF.ar(
		in: snd,
		freq: LFNoise2.kr(1).range(lofreq, hifreq)
	);
    snd = Splay.ar(snd);
    Out.ar(0, snd);
}).add;

)