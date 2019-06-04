classdef radarWaveform
    %ESC synthetic radar waveform generator
    %Waveform types and parameters based on NTIA Technical Memorandum 18-527
    %"Procedures for Laboratory Testing of Environmental Sensing Capability Sensor Devices"
    %Waveforms generated with Matlab phased array toolbox
    %For 'P0N#2' number of chips is fixed to 4 (pulse_width=number_of_chips*chip_width) this enables the use of all possible phase-coding without
    %changing number of chips
    %Phased array toolbox requires integer value for the ratio sampling_frequency/pulse_repetition_rate, therefor sampling rate is set differently
    %than the required sampling rate then the waveform is resampled to the desired sampling rate
    %Additional Requirement for phased.PhaseCodedWaveform, (i.e., 'P0N#2') is that (SampleRate*ChipWidth) must be an integer value,
    %therefore the pulse_width will end-up slightly different than the desired pulse_width
    
    properties
        sampleRate
        pulseModulation  % {'P0N#1','P0N#2','Q3N#1','Q3N#2','Q3N#3'}
        pulseWidth %
        modifiedPulseWidth
        chirpWidth %
        chirpDir   % ch{'Up','Down'}
        PRR        % PRR (pulses per second)
        PPB        %Pulses per Burst
        numWaves % number of waveforms
        waveforms
        PCType='Barker'
        useParallel=false
        %        progBar
        %wgnState logical
        ERROR
    end
    
    properties (Constant, Access=private)
        pulseModulationTypes ={'P0N#1','P0N#2','Q3N#1','Q3N#2','Q3N#3'};
        pulseWidthRanges=[0.5,2.5;13,52;3,5;10,30;50,100].';
        pulseWidthDelta=[0.1 ,13,1,1,5];
        chirpWidthRanges=[nan,nan;nan,nan;50,100;1,10;50,100].';
        chirpWidthDelta=[nan ,nan,10,1,10];
        PRRRanges=[900,1100;300,3000;300,3000;300,3000;300,3000].';
        PPRDelta=[10,10,30,50,100];
        PPBRanges=[15,40;5,20;8,24;2,8;8,24].';
        PPBDelta=[5,5,2,2,2];
        possChirpDir={'Up','Down'};
        PCTypes={'Barker','Frank', 'P1', 'P2', 'P3', 'P4', 'Px', 'Zadoff-Chu'};
    end
    
    methods
        function this = radarWaveform(sampleRate,pulseModulation,numWaves)
            %Construct an instance of this class
            if nargin>1
                %                 if ismember(pulseModulation,this.pulseModulationTypes)
                this.sampleRate = sampleRate;
                this.pulseModulation=pulseModulation;
                this.numWaves=numWaves;
                %                 else
                %                     msgID = 'radarWaveform:initialization';
                %                     msgtext =['pulse modulation type must be one of the following: ',strjoin(this.pulseModulationTypes)];
                %                     this.ERROR=MException(msgID,msgtext);
                %                     throw(this.ERROR);
                %                 end
            end
        end
        
        function this=set.sampleRate(this,sampleRate)
            this.sampleRate = sampleRate;
        end
        
        function this=set.pulseModulation(this,pulseModulation)
            if ismember(pulseModulation,this.pulseModulationTypes)
                this.pulseModulation = pulseModulation;
            else
                msgID = 'radarWaveform:initialization';
                msgtext =['pulse modulation type must be one of the following: ',strjoin(this.pulseModulationTypes)];
                this.ERROR=MException(msgID,msgtext);
                throw(this.ERROR);
            end
        end
        
        function this=set.numWaves(this,numWaves)
            this.numWaves=numWaves;
        end
        
        function this=set.useParallel(this,useParallel)
            if islogical(useParallel)
                this.useParallel=useParallel;
            else
                msgID = 'radarWaveform:initialization';
                msgtext ='useParallel must be logical';
                this.ERROR=MException(msgID,msgtext);
                throw(this.ERROR);
            end
        end
        
        %        function this=set.wgnState(this,wgnState)
        %             if islogical(wgnState)
        %                this.useParallel=wgnState;
        %             else
        %                 msgID = 'radarWaveform:initialization';
        %                 msgtext ='wgnState must be logical';
        %                 this.ERROR=MException(msgID,msgtext);
        %                 throw(this.ERROR);
        %             end
        %         end

        function this=set.PCType(this,PCType)
            if ismember(PCType,this.PCTypes)
                this.PCType = PCType;
            else
                msgID = 'radarWaveform:initialization';
                msgtext =['phase coding type must be one of the following: ',strjoin(this.PCTypes)];
                this.ERROR=MException(msgID,msgtext);
                throw(this.ERROR);
            end
        end
        
        function b=designFilt(filtFs)
            %Fs = 2000790;  % Sampling Frequency
            
            Fpass = 975000;          % Passband Frequency
            Fstop = 1000000;         % Stopband Frequency
            Dpass = 0.057501127785;  % Passband Ripple
            Dstop = 0.0001;          % Stopband Attenuation
            flag  = 'scale';         % Sampling Flag
            
            % Calculate the order from the parameters using KAISERORD.
            [N,Wn,BETA,TYPE] = kaiserord([Fpass Fstop]/(filtFs/2), [1 0], [Dstop Dpass]);
            
            % Calculate the coefficients using the FIR1 function.
            b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
        end
        
        function this = generateRandomPars(this)
            waveIndex=find(ismember(this.pulseModulationTypes,this.pulseModulation));
            this.pulseWidth =1e-6*((this.pulseWidthDelta(waveIndex)*randi([0, (this.pulseWidthRanges(2,waveIndex)- this.pulseWidthRanges(1,waveIndex))...
                /this.pulseWidthDelta(waveIndex)],1,this.numWaves)) +this.pulseWidthRanges(1,waveIndex)).';%(5*randi([0, 50/5],1,this.numWaves)) + 50; % 50 - 100 Step=5
            this.PRR = ((this.PPRDelta(waveIndex)*randi([0, (this.PRRRanges(2,waveIndex)- this.PRRRanges(1,waveIndex))...
                /this.PPRDelta(waveIndex)],1,this.numWaves)) +this.PRRRanges(1,waveIndex)).';%(100*randi([0, 3000/100],1,this.numWaves))+ 333; % 333 - 3333 Step=100 us
            this.PPB = ((this.PPBDelta(waveIndex)*randi([0, (this.PPBRanges(2,waveIndex)- this.PPBRanges(1,waveIndex))...
                /this.PPBDelta(waveIndex)],1,this.numWaves)) +this.PPBRanges(1,waveIndex)).';%(2*randi([0, 16/2],1,this.numWaves))+ 8; % 8 - 24 Step=2
            if ~isnan(this.chirpWidthDelta(waveIndex))
                this.chirpWidth = 1e6*((this.chirpWidthDelta(waveIndex)*randi([0, (this.chirpWidthRanges(2,waveIndex)- this.chirpWidthRanges(1,waveIndex))...
                    /this.chirpWidthDelta(waveIndex)],1,this.numWaves)) +this.chirpWidthRanges(1,waveIndex)).'; %(10*randi([0, 50/10],1,this.numWaves))+ 50; % 50 - 100 Step=10 MHz
                this.chirpDir = this.possChirpDir(randi([1, 2],1,this.numWaves).').';
            else
                this.chirpWidth =nan(this.numWaves,1);
                temp=cell(this.numWaves,1);
                temp(:)={'NaN'};
                this.chirpDir=temp;
            end
        end
        
        function this=initWave(this)
            modifySamplingRate=10*ceil(this.sampleRate./this.PRR).*this.PRR;
            %modifySamplingRate=ceil(this.sampleRate./this.PRR).*this.PRR;
 
            switch this.pulseModulation
                case this.pulseModulationTypes{1}
                    %                     tempW = phased.RectangularWaveform;
                    %                     tempW.SampleRate = this.sampleRate;
                    %                     this.waveforms=cell(this.numWaves,1);
                    %                     this.waveforms(:)={tempW};
                    for I=1:this.numWaves
                        
                        this.waveforms{I,1}=phased.RectangularWaveform;
                        this.waveforms{I,1}.SampleRate = modifySamplingRate(I);
                        this.waveforms{I,1}.NumPulses=this.PPB(I);
                        this.waveforms{I,1}.PRF=this.PRR(I);
                        this.waveforms{I,1}.PulseWidth=this.pulseWidth(I);
                    end
                case this.pulseModulationTypes{2}
                    %                     tempW = phased.PhaseCodedWaveform;
                    %                     tempW.SampleRate = modifySamplingRate(I);
                    %                     this.waveforms=cell(this.numWaves,1);
                    %                     this.waveforms(:)={tempW};
                    NumChips=4;
                    chipWidth=this.pulseWidth/NumChips;
                    modifyChipWidth=ceil(chipWidth.*modifySamplingRate)./modifySamplingRate;
                    this.modifiedPulseWidth=modifyChipWidth*NumChips;
                    for I=1:this.numWaves
                        this.waveforms{I,1}=phased.PhaseCodedWaveform;
                        this.waveforms{I,1}.SampleRate = modifySamplingRate(I);
                        this.waveforms{I,1}.NumPulses=this.PPB(I);
                        this.waveforms{I,1}.PRF=this.PRR(I);
                        %this.waveforms{I,1}.PulseWidth=this.pulseWidth(I);
                        this.waveforms{I,1}.Code = this.PCType;
                        % 'Frank', 'P1', or 'Px'	A perfect square  'Frank', 'P1', or 'Px'
                        % 'P2'	An even number that is a perfect square
                        % 'Barker'	2, 3, 4, 5, 7, 11, or 13
                        this.waveforms{I,1}.NumChips = NumChips;
                        this.waveforms{I,1}.ChipWidth=(modifyChipWidth(I));
                    end
                case this.pulseModulationTypes(3:end)
                    %                     tempW = phased.LinearFMWaveform;
                    %                     tempW.SampleRate = this.sampleRate;
                    %                     this.waveforms=cell(this.numWaves,1);
                    %                     this.waveforms(:)={tempW};
                    %  modifySamplingRate=ceil(this.sampleRate./this.PRR).*this.PRR;
                    for I=1:this.numWaves
                        this.waveforms{I,1}=phased.LinearFMWaveform;
                        this.waveforms{I,1}.SampleRate = modifySamplingRate(I);
                        this.waveforms{I,1}.SweepInterval='Symmetric';
                        this.waveforms{I,1}.NumPulses=this.PPB(I);
                        this.waveforms{I,1}.PRF=this.PRR(I);
                        this.waveforms{I,1}.PulseWidth=this.pulseWidth(I);
                        this.waveforms{I,1}.SweepBandwidth=this.chirpWidth(I);
                        this.waveforms{I,1}.SweepDirection=this.chirpDir{I};
                    end
            end
        end
        
        function waveOut=generateWave(this,uiFig)
            progBarFalg=false;
            if nargin>1
                progBarFalg=true;
            end
            if this.useParallel
                if progBarFalg
                    progBar =parforuiprogressdlg(uiFig, 'Generating waveforms',this.numWaves,'Working on wavefom number: ');
                end
                parfor I=1:this.numWaves
                    if progBarFalg
                        progBar.iterate(1);
                    end
                    sigOut{I,:}=this.waveforms{I}();
                    [p,q] = rat(this.sampleRate/this.waveforms{I}.SampleRate,1e-4);
                    waveOut{I,:}=resample(sigOut{I,:},p,q,0,10);% If n = 0, resample performs nearest-neighbor interpolation
                    % resample(sig,p,q,n,Beta) Beta: Shape parameter of Kaiser window, specified as a positive real scalar. Increasing beta widens the mainlobe of the window
                    % used to design the antialiasing filter and decreases the amplitude of the window’s sidelobes.
                end
                close(progBar);
                
            else
                
                if progBarFalg
                    progBar=constructProgBar(this,uiFig);
                end
                for I=1:this.numWaves
                    
                    if progBarFalg
                        incPrgBar(this,progBar,I,this.numWaves);
                        if progBar.CancelRequested
                            break
                        end
                    end
                    
                    sigOut{I,:}=this.waveforms{I}();
                    [p,q] = rat(this.sampleRate/this.waveforms{I}.SampleRate,1e-4);
                    waveOut{I,:}=resample(sigOut{I,:},p,q,0,10);% If n = 0, resample performs nearest-neighbor interpolation
                end
                
            end
            
        end
        
        function progBar=constructProgBar(this,uiFig)
            progBar = uiprogressdlg(uiFig,'Title','Generating waveforms',...
                'Message','1','Cancelable','on');
        end
        
        function incPrgBar(this,progBar,val,num)
            progBar.Value = val/num;
            progBar.Message = sprintf('Working on wavefom number: %d out of %d',val,num);
        end
        
        function outTable=getParsTable(this)
            VariableNames={'PulseWidth', 'PulsesPerSecond', 'PulsesPerBurst', 'ChirpWidth','ChirpDirection','SamplingFrequency','ActualPulseWidth','PhaseCodingType'};
            if strcmp(this.pulseModulation,'P0N#2')
%               VariableNames={'PulseWidth', 'PulsesPerSecond', 'PulsesPerBurst', 'ChirpWidth','ChirpDirection','SamplingFrequency','ActualPulseWidth','PhaseCodingType'};  
                temp=cell(this.numWaves,1);
                temp(:)={this.PCType};
                outTable=table(this.pulseWidth, this.PRR, this.PPB, this.chirpWidth, this.chirpDir,this.sampleRate*ones(this.numWaves,1),this.modifiedPulseWidth,temp,'VariableNames',VariableNames);
            else
                %                VariableNames={'PulseWidth', 'PulsesPerSecond', 'PulsesPerBurst', 'ChirpWidth','ChirpDirection','SamplingFrequency'};
                temp= cell(this.numWaves, 1);
                temp(:) = {'NaN'};
                outTable=table(this.pulseWidth, this.PRR, this.PPB, this.chirpWidth, this.chirpDir,this.sampleRate*ones(this.numWaves,1),this.pulseWidth,temp,'VariableNames',VariableNames);
            end
        end
        
        function outConst=getConstants(this)
            outConst.pulseModulationTypes=this.pulseModulationTypes;
            outConst.pulseWidthRanges=this.pulseWidthRanges;
            outConst.pulseWidthDelta=this.pulseWidthDelta;
            outConst.chirpWidthRanges=this.chirpWidthRanges;
            outConst.chirpWidthDelta=this.chirpWidthDelta;
            outConst.PRRRanges=this.PRRRanges;
            outConst.PPRDelta=this.PPRDelta;
            outConst.PPBRanges=this.PPBRanges;
            outConst.PPBDelta=this.PPBDelta;
            outConst.possChirpDir=this.possChirpDir;
            outConst.PCTypes=this.PCTypes;
        end
        
    end
end

