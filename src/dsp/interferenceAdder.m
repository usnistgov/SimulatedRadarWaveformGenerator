...%% Legal Disclaimer
...% NIST-developed software is provided by NIST as a public service. 
...% You may use, copy and distribute copies of the software in any medium,
...% provided that you keep intact this entire notice. You may improve,
...% modify and create derivative works of the software or any portion of
...% the software, and you may copy and distribute such modifications or
...% works. Modified works should carry a notice stating that you changed
...% the software and should note the date and nature of any such change.
...% Please explicitly acknowledge the National Institute of Standards and
...% Technology as the source of the software.
...% 
...% NIST-developed software is expressly provided "AS IS." NIST MAKES NO
...% WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
...% OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
...% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
...% AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
...% OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
...% THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY 
...% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS 
...% THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
...% RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
...% 
...% You are solely responsible for determining the appropriateness of
...% using and distributing the software and you assume all risks
...% associated with its use, including but not limited to the risks and
...% costs of program errors, compliance with applicable laws, damage to 
...% or loss of data, programs or equipment, and the unavailability or
...% interruption of operation. This software is not intended to be used in
...% any situation where a failure could cause risk of injury or damage to
...% property. The software developed by NIST employees is not subject to
...% copyright protection within the United States.

classdef interferenceAdder
    %RADARINTERFERENCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        inType
        %        numWaveforms
        inParameters
    end
    
    methods
        function this = interferenceAdder(inType)
            %interferenceAdder Construct an instance of this class
            % inType currently supports wgn
            this.inType =inType;
            %this.numWaveforms=numWaveforms;
        end
        
        function this=setInterferencePar(this,inPar)
            
            if strcmp(this.inType,'wgn')
                %inPar for wgn must be a struct and have these parameters
                %powerLevelMode: <,'Power Level Range','SNR Range'>
                %rangedBmOrdB: [lower,step,upper]
                %radarPeakPowerdBmP1MHzFixed:  NaN for SNR mode or value for Power Level mode
                %noisePowerdBmP1MHzFixed: value for SNR mode or NaN for Power Level mode
                %includeNoiseOnlySet: true false whether to include noise only waveforms
                %waveformDurationMode: <'keep' (don't change orignal length), 'fix to max' (fix length to the maximum in the set), 'fix to' (set all to a fixed ms duration>
                %fixedWaveformDuration: for 'fix to' mode ms duration
                %need to add check for correct pars in the future
                this.inParameters.wgn=inPar;
            end
            
            
        end
        
        function [waveformCell,allWaveformTable]=addInterference(this,waveformCell,allWaveformTable)
            %addInterference passthrough function
            switch this.inType
                case 'wgn'
                    [waveformCell,allWaveformTable]= addWGN(this,waveformCell,allWaveformTable);
                otherwise
                    waveformCell=[];
                    allWaveformTable=[];
                    %newIndex=[];
            end
            
        end
        
        function [waveformCell,allWaveformTable]= addWGN(this,waveformCell,allWaveformTable)
            %addWGN add wgn to the waveforms
            %   Detailed explanation goes here
            lowerVal=this.inParameters.wgn.rangedBmOrdB(1);
            stepVal=this.inParameters.wgn.rangedBmOrdB(2);
            upperVal=this.inParameters.wgn.rangedBmOrdB(3);
            %sigScale=this.inParameters.wgn.sigScale;
            radarSignalStartTime=zeros(length(waveformCell),1);
            if strcmp(this.inParameters.wgn.waveformDurationMode,'fix to max')||strcmp(this.inParameters.wgn.waveformDurationMode,'fix to')
                waveformLength=cellfun(@length,waveformCell);
                if strcmp(this.inParameters.wgn.waveformDurationMode,'fix to max')
                    newAllLength=repmat(max(waveformLength),length(waveformLength),1);
                end
                if strcmp(this.inParameters.wgn.waveformDurationMode,'fix to')
                    newAllLength=round((this.inParameters.wgn.fixedWaveformDuration*1e-3)*allWaveformTable.SamplingFrequency);
                end
                diffInLength=newAllLength-waveformLength;
                diffInLength(diffInLength<=0)=1;
                waveformStartFrom=arrayfun(@(x) randi([1,x],1,1), diffInLength);
                waveformEndsAt=waveformStartFrom+waveformLength-1;
                waveformEndsAt(waveformEndsAt>newAllLength)=newAllLength(waveformEndsAt>newAllLength);
                waveformOriginalLengthTrim=newAllLength;
                waveformOriginalLengthTrim(waveformLength<newAllLength)=waveformLength(waveformLength<newAllLength);
                for I=1:length(waveformCell)
                    temp=zeros(newAllLength(I),1);
                    temp(waveformStartFrom(I):waveformEndsAt(I))=waveformCell{I}(1:waveformOriginalLengthTrim(I));
                    waveformCell{I}=temp;
                end
                 radarSignalStartTime=waveformStartFrom./allWaveformTable.SamplingFrequency;
            end
            %                   example of parameter struct
            %                 radarPeakPowerdBmP1MHzFixed: NaN
            %         noisePowerdBmP1MHzFixed: -109
            %                  powerLevelMode: 'SNR Range'
            %                    rangedBmOrdB: [20 2 20]
            %             includeNoiseOnlySet: 1
            %            waveformDurationMode: 'fix to'
            %           fixedWaveformDuration: 80
            rangedBmOrdB=lowerVal:stepVal:upperVal;
            % add baseband freq shift
            radarSignalCenterFreq=zeros(length(waveformCell),1);
            if strcmp(this.inParameters.wgn.basebandFreqMode,'set at')||strcmp(this.inParameters.wgn.basebandFreqMode,'random between +-')
                if strcmp(this.inParameters.wgn.basebandFreqMode,'set at')
                    radarSignalCenterFreq=this.inParameters.wgn.basebandFreqValue*ones(length(waveformCell),1);
                end
                if strcmp(this.inParameters.wgn.basebandFreqMode,'random between +-')
                    frqBound=(this.inParameters.wgn.basebandFreqValue/100)*(allWaveformTable.SamplingFrequency/2);
                    radarSignalCenterFreq=arrayfun(@(x) randi([-1*x,x]),frqBound);
                end
                if this.inParameters.wgn.useParallel
                    parfor J=1:numel(waveformCell)
                        t=(0:length(waveformCell{J})-1).'/allWaveformTable.SamplingFrequency(J);
                        waveformCell{J}=waveformCell{J}.*exp(2i*pi*radarSignalCenterFreq(J)*t);
                        %waveformCell
                    end
                else
                    for J=1:numel(waveformCell)
                        t=(0:length(waveformCell{J})-1).'/allWaveformTable.SamplingFrequency(J);
                        waveformCell{J}=waveformCell{J}.*exp(2i*pi*radarSignalCenterFreq(J)*t);
                        %waveformCell
                    end
                end
            end
            % end baseband freq shift
            if this.inParameters.wgn.useParallel 
                parfor I=1:length(waveformCell)
                    peakPer1MHz(I,1)=measurePeakIn1MHz(this,waveformCell{I},allWaveformTable.SamplingFrequency(I));
                    randomNoisePowdBmOrSNRdB(I,1)=rangedBmOrdB(randi([1,length(rangedBmOrdB)],1));
                end
            else
                for I=1:length(waveformCell)
                    peakPer1MHz(I,1)=measurePeakIn1MHz(this,waveformCell{I},allWaveformTable.SamplingFrequency(I));
                    randomNoisePowdBmOrSNRdB(I,1)=rangedBmOrdB(randi([1,length(rangedBmOrdB)],1));
                end
            end
            
            radarStatus=true(length(waveformCell),1);
            allWaveformTable=addvars(allWaveformTable,radarStatus);
            allWaveformTable=addvars(allWaveformTable,radarSignalCenterFreq);
            allWaveformTable=addvars(allWaveformTable,radarSignalStartTime);
            
            if strcmp(this.inParameters.wgn.powerLevelMode,'Power Level Range')
                noisePowerTotaldBw=randomNoisePowdBmOrSNRdB-30+pow2db(allWaveformTable.SamplingFrequency./1e6);
                desiredPeakPowerdBwPerMHz=repmat(this.inParameters.wgn.radarPeakPowerdBmP1MHzFixed-30,[length(waveformCell),1]);
                adjustPeaksBy=sqrt(db2pow(desiredPeakPowerdBwPerMHz))./peakPer1MHz;
                %noisePower=lowerVal:stepVal:upperVal;
                %wPowdBmMat=repmat(rangedBm,[length(app.allSigs),1]);
                allWaveformTable=addvars(allWaveformTable,desiredPeakPowerdBwPerMHz+30,randomNoisePowdBmOrSNRdB,'NewVariableNames',{'PeakPowerdBmPer1MHz','NoisePowerdBmPerMHz'});
                
            else
                noisePowerTotaldBw=this.inParameters.wgn.noisePowerdBmP1MHzFixed-30+pow2db(allWaveformTable.SamplingFrequency./1e6);
                desiredPeakPowerdBwPerMHz=randomNoisePowdBmOrSNRdB+(noisePowerTotaldBw-pow2db(allWaveformTable.SamplingFrequency./1e6)); %SNR_in_1Mhz=sigPow_dB_in_1MHz-noisePow_dB_in_1Mhz-->> sigPow_dB=SNR+noisePow_dB
                adjustPeaksBy=sqrt(db2pow(desiredPeakPowerdBwPerMHz))./peakPer1MHz;    % desiredPeakPow=scale*currentPeakPow
                %rangedBm=(pow2db(sigScale^2)+30-lowerVal):stepVal:(pow2db(sigScale^2)+30-upperVal);
                %wPowdBmMat=repmat(rangedBm,[length(app.allSigs),1]);
                allWaveformTable=addvars(allWaveformTable,randomNoisePowdBmOrSNRdB,repmat(this.inParameters.wgn.noisePowerdBmP1MHzFixed,[length(waveformCell),1]),'NewVariableNames',{'SNR','NoisePowerdBmPerMHz'});
            end

            %                 for I=1:length(waveformCell)
            %                     wpow{I,1}=rangedBm(randi([1,length(rangedBm)]))+pow2db((allWaveformTable.SamplingFrequency(I)/1e6));%+db2pow(3);%%%check check
            %                 end
            if this.inParameters.wgn.useParallel
                parfor I=1:length(waveformCell)
                    %peakPer1MHz=measurePeakIn1MHz(this,waveformCell{I},allWaveformTable.SamplingFrequency(I));
                    waveformCell{I}=adjustPeaksBy(I)*waveformCell{I}+wgn(length(waveformCell{I}),1,noisePowerTotaldBw(I),'dBW','complex');
                end
            else
                for I=1:length(waveformCell)
                    %peakPer1MHz=measurePeakIn1MHz(this,waveformCell{I},allWaveformTable.SamplingFrequency(I));
                    waveformCell{I}=adjustPeaksBy(I)*waveformCell{I}+wgn(length(waveformCell{I}),1,noisePowerTotaldBw(I),'dBW','complex');
                end
            end
            
            if this.inParameters.wgn.includeNoiseOnlySet
                if this.inParameters.wgn.useParallel
                    parfor I=1:length(waveformCell)
                        noiseWaveformCell{I,1}=wgn(length(waveformCell{I}),1,noisePowerTotaldBw(I),'dBW','complex');
                    end
                else
                    for I=1:length(waveformCell)
                        noiseWaveformCell{I,1}=wgn(length(waveformCell{I}),1,noisePowerTotaldBw(I),'dBW','complex');
                    end
                end
                
                
                waveformCell=[waveformCell;noiseWaveformCell];
                            
                numericOrLogicalVars = varfun(@(x) isnumeric(x)|islogical(x),allWaveformTable,'output','uniform');
                newCellforWGN=cell(height(allWaveformTable),width(allWaveformTable));
                newCellforWGN(repmat(~numericOrLogicalVars,[height(allWaveformTable),1]))={'NaN'};
                varsToChange={'SamplingFrequency','radarStatus','NoisePowerdBmPerMHz'};
                varsToChangeLogical=and(numericOrLogicalVars,ismember(allWaveformTable.Properties.VariableNames,varsToChange));
                newCellforWGN(repmat(~varsToChangeLogical&numericOrLogicalVars,[height(allWaveformTable),1]))={NaN};
                newCellforWGN(repmat(ismember(allWaveformTable.Properties.VariableNames,varsToChange{1}),[height(allWaveformTable),1]))=...
                    mat2cell(allWaveformTable.SamplingFrequency,ones(height(allWaveformTable),1));
                newCellforWGN(repmat(ismember(allWaveformTable.Properties.VariableNames,varsToChange{2}),[height(allWaveformTable),1]))={false};
                newCellforWGN(repmat(ismember(allWaveformTable.Properties.VariableNames,varsToChange{3}),[height(allWaveformTable),1]))=...
                    mat2cell(noisePowerTotaldBw+30-pow2db(allWaveformTable.SamplingFrequency./1e6),ones(height(allWaveformTable),1));
                allWaveformTable=[allWaveformTable;cell2table(newCellforWGN,'VariableNames',allWaveformTable.Properties.VariableNames)];
                
            end
            
            duration=cellfun(@length,waveformCell)./allWaveformTable.SamplingFrequency;
            allWaveformTable=addvars(allWaveformTable,duration);
            % randomize twice 
            newIndex=randperm(length(waveformCell)).';
            waveformCell=waveformCell(newIndex,:);
            allWaveformTable=allWaveformTable(newIndex,:);
            
            newIndex=randperm(length(waveformCell)).';
            waveformCell=waveformCell(newIndex,:);
            allWaveformTable=allWaveformTable(newIndex,:);
        end
        
        function peakInMHz=measurePeakIn1MHz(this,sig,Fs)
            %1. design MeasFilt
            FsMHz=Fs/1e6;
            Hd=design1MFilter(this,FsMHz);
            t=(0:length(Hd.Numerator)-1)/Fs;
            %Calculate max location in freq domain
% a faster approach             
%             NFFT=length(sig);
%             moveAveResN=64;
%             moveAveResF=Fs/moveAveResN;
%             numPointsToAvoidFromSides=ceil(NFFT/(Fs/0.5e6));% avoid 0.5 MHz from the sides
%             f=(-NFFT/2:NFFT/2-1)*Fs/NFFT;
%             sigMoveAve = movmean(abs(fftshift(fft(sig,NFFT))),moveAveResN);
%             sigMoveAve(1:numPointsToAvoidFromSides)=0;sigMoveAve(end-numPointsToAvoidFromSides:end)=0;
%             [~,mIndx]=max(sigMoveAve);
%             
            NFFT=2048;
            win = hanning(NFFT,'periodic');
            [sigSF,f,ts] =stft(sig,Fs,'Window',win,'OverlapLength',256,'FFTLength',NFFT);
            sigSFSum=sum(abs(sigSF),2);
            numPointsToAvoidFromSides=ceil(NFFT/(Fs/0.5e6));
            sigSFSum(1:numPointsToAvoidFromSides)=0;sigSFSum(end-numPointsToAvoidFromSides:end)=0;
            [~,mIndx]=max(sigSFSum);
            
            Hd.Numerator=Hd.Numerator.*exp(2i*pi*f(mIndx)*t);
            peakInMHz=max(abs(Hd(sig)));
            
        end
        
        function Hd=design1MFilter(this,FsMHz)
            %FIRKAISERFLIT1MPER10M Returns a discrete-time filter object.
            % MATLAB Code
            % Generated by MATLAB(R) 9.5 and DSP System Toolbox 9.7.
            % Generated on: 25-Feb-2019 13:29:33
            % FIR Window Lowpass filter designed using the FIR1 function.
            % All frequency values are in MHz.
            %FsMHz = 10;  % Sampling Frequency
            Fpass = 0.48;             % Passband Frequency
            Fstop = 0.56;             % Stopband Frequency
            Dpass = 0.057501127785;   % Passband Ripple
            Dstop = 0.0031622776602;  % Stopband Attenuation
            flag  = 'scale';          % Sampling Flag
            % Calculate the order from the parameters using KAISERORD.
            [N,Wn,BETA,TYPE] = kaiserord([Fpass Fstop]/(FsMHz/2), [1 0], [Dstop Dpass]);
            % Calculate the coefficients using the FIR1 function.
            b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
            %Hd = dfilt.dffir(b);
            Hd = dsp.FIRFilter('Numerator',b);
        end
        
    end
end

