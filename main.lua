Utils={}
Utils.scale=function(x,a,b,na,nb)
  local i=(x-a)/(b-a)
  return na*i+(nb*(1-i))
end
----------------------
----------------------
SinOsc={phase=0,freq=440,amp=1}
SinOsc.__index=SinOsc
function SinOsc.new()
  local o={}
  setmetatable(o,SinOsc)
  return o
end
function SinOsc:Process(samplerate)
  self.phase=self.phase+(math.pi*self.freq/samplerate)
  return math.sin(self.phase)*self.amp;
end
----------------------
----------------------
PulseOsc={phase=0,freq=440,amp=1,width=0.5}
PulseOsc.__index=PulseOsc
function PulseOsc.new()
  local o={}
  setmetatable(o,PulseOsc)
  return o
end
function PulseOsc:Process(samplerate)
  self.phase=self.phase+self.freq*0.5/samplerate
  while self.phase>1 do self.phase=self.phase-1 end
  if self.phase > self.width then return 1*self.amp else return -1*self.amp end
end
----------------------
----------------------
SawOsc={phase=0,freq=440,amp=1,width=0.5}
SawOsc.__index=SawOsc
function SawOsc.new()
  local o={}
  setmetatable(o,SawOsc)
  return o
end
function SawOsc:Process(samplerate)
  self.phase=self.phase+self.freq*0.5/samplerate
  while self.phase>1 do self.phase=self.phase-1 end
  return (self.phase*2-1)*self.amp
end
----------------------
----------------------
TriOsc={phase=0,freq=440,amp=1,width=0.5}
TriOsc.__index=TriOsc
function TriOsc.new()
  local o={}
  setmetatable(o,TriOsc)
  return o
end
function TriOsc:Process(samplerate)
  self.phase=self.phase+self.freq*0.5/samplerate
  while self.phase>1 do self.phase=self.phase-1 end
  return (math.abs(self.phase-0.5)*4-1)*self.amp
end
----------------------
----------------------
Line={from=1,to=0,duration=1,delta=-1}
Line.__index = Line
function Line.new()
  local o={}
  setmetatable(o,Line)
  return o
end
function Line:Process(samplerate)
  local output=0
  if self.delta>-1 then
    output=self.to*self.delta/self.duration + self.from*(self.duration-self.delta)/self.duration
    self.delta=self.delta+1/samplerate
    if self.delta>self.duration+1/samplerate then self.delta = -1 end
  else
    output=self.to
  end
  return output
end
function Line:Reset()
  self.delta=0
end
----------------------
----------------------
Filter={filterType="lowpass",a0=1,a1=0,a2=0,b1=0,b2=0,Fc=0.25,Q=0.7,peakGain=0,z1=0,z2=0}
Filter.__index=Filter
function Filter.new(filterType)
  local o={}
  setmetatable(o,Filter)
  o.filterType=filterType
  o:SetType(o.filterType)
  return o
end
function Filter:CalcBiquad()
  local norm
  local V=math.pow(10,math.abs(self.peakGain)/20)
  local K=math.tan(math.pi*self.Fc)
  if self.filterType=="lowpass" then
    norm = 1 / (1 + K / self.Q + K * K)
    self.a0 = K * K * norm
    self.a1 = 2 * self.a0
    self.a2 = self.a0
    self.b1 = 2 * (K * K - 1) * norm
    self.b2 = (1 - K / self.Q + K * K) * norm
  end
  if self.filterType=="highpass" then
    norm = 1 / (1 + K / self.Q + K * K);
    self.a0 = 1 * norm;
    self.a1 = -2 * self.a0;
    self.a2 = self.a0;
    self.b1 = 2 * (K * K - 1) * norm;
    self.b2 = (1 - K / self.Q + K * K) * norm;
  end
  if self.filterType=="bandpass" then
    norm = 1 / (1 + K / self.Q + K * K);
    self.a0 = K / self.Q * norm;
    self.a1 = 0;
    self.a2 = -self.a0;
    self.b1 = 2 * (K * K - 1) * norm;
    self.b2 = (1 - K / self.Q + K * K) * norm;
  end
  if self.filterType=="notch" then
    norm = 1 / (1 + K / self.Q + K * K);
    self.a0 = (1 + K * K) * norm;
    self.a1 = 2 * (K * K - 1) * norm;
    self.a2 = self.a0;
    self.b1 = self.a1;
    self.b2 = (1 - K / self.Q + K * K) * norm;
  end
  if self.filterType=="peak" then
    if self.peakGain >= 0 then
      norm = 1 / (1 + 1/self.Q * K + K * K);
      self.a0 = (1 + V/self.Q * K + K * K) * norm;
      self.a1 = 2 * (K * K - 1) * norm;
      self.a2 = (1 - V/self.Q * K + K * K) * norm;
      self.b1 = self.a1;
      self.b2 = (1 - 1/self.Q * K + K * K) * norm;
    else
      norm = 1 / (1 + V/self.Q * K + K * K);
      self.a0 = (1 + 1/self.Q * K + K * K) * norm;
      self.a1 = 2 * (K * K - 1) * norm;
      self.a2 = (1 - 1/self.Q * K + K * K) * norm;
      self.b1 = self.a1;
      self.b2 = (1 - V/self.Q * K + K * K) * norm;
    end
  end
  if self.filterType=="lowshelf" then
    if self.peakGain >= 0 then
        norm = 1 / (1 + math.sqrt(2) * K + K * K);
        self.a0 = (1 + math.sqrt(2*V) * K + V * K * K) * norm;
        self.a1 = 2 * (V * K * K - 1) * norm;
        self.a2 = (1 - math.sqrt(2*V) * K + V * K * K) * norm;
        self.b1 = 2 * (K * K - 1) * norm;
        self.b2 = (1 - math.sqrt(2) * K + K * K) * norm;
    else
        norm = 1 / (1 + math.sqrt(2*V) * K + V * K * K);
        self.a0 = (1 + math.sqrt(2) * K + K * K) * norm;
        self.a1 = 2 * (K * K - 1) * norm;
        self.a2 = (1 - math.sqrt(2) * K + K * K) * norm;
        self.b1 = 2 * (V * K * K - 1) * norm;
        self.b2 = (1 - math.sqrt(2*V) * K + V * K * K) * norm;
    end
  end
  if self.filterType=="highshelf" then
    if self.peakGain >= 0 then
        norm = 1 / (1 + math.sqrt(2) * K + K * K);
        self.a0 = (V + math.sqrt(2*V) * K + K * K) * norm;
        self.a1 = 2 * (K * K - V) * norm;
        self.a2 = (V - math.sqrt(2*V) * K + K * K) * norm;
        self.b1 = 2 * (K * K - 1) * norm;
        self.b2 = (1 - math.sqrt(2) * K + K * K) * norm;
    else
        norm = 1 / (V + math.sqrt(2*V) * K + K * K);
        self.a0 = (1 + math.sqrt(2) * K + K * K) * norm;
        self.a1 = 2 * (K * K - 1) * norm;
        self.a2 = (1 - math.sqrt(2) * K + K * K) * norm;
        self.b1 = 2 * (K * K - V) * norm;
        self.b2 = (V - math.sqrt(2*V) * K + K * K) * norm;
    end
  end
end
function Filter:SetType(filterType)
  self.filterType=filterType
  self:CalcBiquad()
end
function Filter:SetFreq(freq,samplerate)
  self.Fc=freq/samplerate
  self:CalcBiquad()
end
function Filter:SetQ(q)
  self.Q=q
  self:CalcBiquad()
end
function Filter:Process(input)
  local output = input * self.a0 + self.z1;
  self.z1 = input * self.a1 + self.z2 - self.b1 * output;
  self.z2 = input * self.a2 - self.b2 * output;
  return output;
end
----------------------
----------------------
Voice={}
Voice.__index=Voice
function Voice.new()
  local o={}
  setmetatable(o,Voice)
  o.osc=PulseOsc.new()
  o.release=Line.new()
  o.attack=Line.new()
  o.attack.from=0
  o.attack.to=1
  o.attack.duration=0.005
  o.filter=Filter.new("lowpass")
  return o
end
function Voice:PlayNote(note)
  self.osc.freq=440*math.pow(2,(note-69)/12);
  self.attack:Reset()
  self.release:Reset()
end
function Voice:Process(sr)
  local env=self.attack:Process(sr)*self.release:Process(sr)
  local expEnv=math.pow(env,10)
  self.osc.width=Utils.scale(expEnv,0,1,0.1,0.5)
  self.filter:SetFreq(Utils.scale(expEnv,0,1,4000,50),sr)
  return self.filter:Process(self.osc:Process(sr))*env
end
----------------------
----------------------
Synth={}
Synth.__index=Synth
function Synth.new()
  local o={}
  setmetatable(o,Synth)
  o.numVoices=50
  o.voices={}
  o.voiceIndex=1
  o.filter=Filter.new("lowshelf")
  for i=1,o.numVoices do
    table.insert(o.voices,Voice.new())
  end
  return o
end
function Synth:PlayNote(note)
  self.voices[self.voiceIndex]:PlayNote(note)
  self.voiceIndex=(self.voiceIndex+1)%self.numVoices
  self.voiceIndex=self.voiceIndex+1
end
function Synth:Process(sr)
  local output=0
  for i=1,#(self.voices) do
    if self.voices[i].release.delta>-1 then output=output+self.voices[i]:Process(sr) end
  end
  return self.filter:Process(output/self.numVoices)
end
----------------------
----------------------