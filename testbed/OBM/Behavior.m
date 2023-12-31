function [OccupantMatrix] = Behavior(...
    OccupantMatrix,SocialMatrix,RuleVector,postpredmat_sens,controls,...
    closetting,Season,group_logisticregression_inter,...
    group_logisticregression_arrive,trm,n)
% Behavior - Update occupant behavior state and adjustment possibilities
% by running one of 6 possible user-defined behavior modeling rules

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
%    Copyright 2016 Jared Langevin                                         %
%                                                                          %
%    Licensed under the Apache License, Version 2.0 (the "License");       %
%    you may not use this file except in compliance with the License.      %
%    You may obtain a copy of the License at                               %
%                                                                          %
%        http://www.apache.org/licenses/LICENSE-2.0                        %
%                                                                          %
%    Unless required by applicable law or agreed to in writing, software   %
%    distributed under the License is distributed on an "AS IS" BASIS,     %
%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       %
%    implied. See the License for the specific language governing          %
%    permissions and limitations under the License.                        %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% extrinsic function
coder.extrinsic('mnrnd');

%% Declare variable
tempmn = zeros(1,3);

%% Run non-agent-based (e.g., random choice or regression-based) behavior rules
% Behavior states are independently simulated from one time step to the
% next under these rules

% Set operative temperature
TOp = (OccupantMatrix.IndoorEnvironmentVectorBase(1)+...
    OccupantMatrix.IndoorEnvironmentVectorBase(4))/2;

% Execute any non-agent-based rule for available behaviors
if (any(RuleVector < 4) == 1);
    % Loop through all available behaviors
    for p = 2:length(OccupantMatrix.BehaviorPossibilitiesMatrix)
        % Check to see if the given behavior is possible
        if any(abs(OccupantMatrix.BehaviorPossibilitiesMatrix(:,p))>0)==1;
            % Clothing behavior
            if (p == 2);   
                % Random guess behavior rule
                if RuleVector(p) == 1;  
                    % Initialize multinomial draw for clothing state
                    % with equal probabilities of each state
                    tempmn = mnrnd(1,[1/3 1/3 1/3]);

                    % Determine clothing state by the draw (1st yields
                    % warm clothing choice, second yields medium clothing
                    % choice, third yields lower clothing choice
                    if tempmn(1) == 1;
                        OccupantMatrix.CurrentClothing = 0.85;
                    elseif tempmn(3) == 1;
                        OccupantMatrix.CurrentClothing = 0.4;                    
                    else
                        OccupantMatrix.CurrentClothing = 0.6;    
                    end
                % User-defined logistic regression rule
                elseif RuleVector(p) == 2;
                    if (any(isnan(...
                            group_logisticregression_inter(p,:)))==0)&&...
                            (any(isnan(...
                            group_logisticregression_arrive(p,:)))==0)
                        % Probability of clothing up/down upon arrival at 
                        % the office 
                        if (OccupantMatrix(...
                                n).OccupancyStateVectorPrevious(1)...
                                == 0)||(OccupantMatrix(...
                                n).OccupancyStateVectorPrevious(1) == 255)
                            % Probability clothing is up
                            probon1 = (...
                                exp(group_logisticregression_arrive(1,1)+...
                                (group_logisticregression_arrive(1,2)*TOp)+...
                                (group_logisticregression_arrive(1,3)*...
                                (OccupantMatrix.OutdoorEnvironmentVector(...
                                1)))))/(1+(exp(...
                                group_logisticregression_arrive(1,1)+...
                                (group_logisticregression_arrive(1,2)*TOp)+...
                                (group_logisticregression_arrive(1,3)*(...
                                OccupantMatrix.OutdoorEnvironmentVector(...
                                1))))));            
                            % Probability clothing is down
                            probon2 = (...
                                exp(group_logisticregression_arrive(2,1)+...
                                (group_logisticregression_arrive(2,2)*TOp)+...
                                (group_logisticregression_arrive(2,3)*...
                                (OccupantMatrix.OutdoorEnvironmentVector(...
                                1)))))/(1+(exp(...
                                group_logisticregression_arrive(2,1)+...
                                (group_logisticregression_arrive(2,2)*TOp)+...
                                (group_logisticregression_arrive(2,3)*(...
                                OccupantMatrix.OutdoorEnvironmentVector(...
                                1))))));            
                            % Probability clothing is at medium level
                            probreg = (1-probon1-probon2);
                        % Probability of clothing up/down for intermediate
                        % time at the office
                        else
                            % Probability clothing is up
                            probon1 = (...
                                exp(group_logisticregression_inter(1,1)+...
                                (group_logisticregression_inter(1,2)*TOp)+...
                                (group_logisticregression_inter(1,3)*...
                                (OccupantMatrix.OutdoorEnvironmentVector(...
                                1)))))/(1+(...
                                exp(group_logisticregression_inter(1,1)+...
                                (group_logisticregression_inter(1,2)*TOp)+...
                                (group_logisticregression_inter(1,3)*...
                                (OccupantMatrix.OutdoorEnvironmentVector(...
                                1))))));            
                            % Probability clothing is down
                            probon2 = (...
                                exp(group_logisticregression_inter(2,1)+...
                                (group_logisticregression_inter(2,2)*TOp)...
                                +(group_logisticregression_inter(2,3)*...
                                (OccupantMatrix.OutdoorEnvironmentVector(...
                                1)))))/(1+(exp(...
                                group_logisticregression_inter(2,1)+...
                                (group_logisticregression_inter(2,2)*TOp)+...
                                (group_logisticregression_inter(2,3)*(...
                                OccupantMatrix.OutdoorEnvironmentVector(...
                                1))))));            
                            % Probability clothing is at medium level
                            probreg = (1-probon1-probon2);
                        end
                        
                        % Initialize multinomial draw for clothing state
                        % with regression-based probabilities of each state
                        tempmn = mnrnd(1,[probon1 probreg probon2]);

                            % Determine clothing state by the draw (1st
                            % yields warm clothing choice, second yields 
                            % medium clothing choice, third yields lower
                            % clothing choice
                            if tempmn(1) == 1;
                                OccupantMatrix.CurrentClothing = 0.85;
                            elseif tempmn(3) == 1;
                                OccupantMatrix.CurrentClothing = 0.4;                    
                            else
                                OccupantMatrix.CurrentClothing = 0.6;    
                            end
                    end
                end
            % Behavior other than clothing adjustment    
            elseif (p>2)
                % Create temporary possibilities vector for the given 
                % behavior
                possibilitiestemp = ...
                    OccupantMatrix.BehaviorPossibilitiesMatrix(:,p);
                % Filter possibilities temp to include only non-zero
                % entries
                possibilitiestemp = ...
                    possibilitiestemp(possibilitiestemp(:)>0);
                
                % Random guess behavior rule
                if RuleVector(p) == 1
                    % Behavior with only 2 possible states
                    if size(possibilitiestemp,1)==1;
                        % Random binomial draw to determine state
                        tempbinom = binornd(1,(1/2));
                        % Case where a positive behavior state is drawn
                        if tempbinom ==1               
                           % Determine direction of behavior (cool
                           % or warm) based on behavior possibilities
                           % matrix defined from Excel setup file
                           if OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                   1,p) > 0; 
                                OccupantMatrix.BehaviorStatesVector(p) = -1;
                           else
                                OccupantMatrix.BehaviorStatesVector(p) = 1;
                           end
                        % Case where there is no drawn state change   
                        else
                            OccupantMatrix.BehaviorStatesVector(p) = 0;
                        end
                    % Behavior with more than 2 possible states
                    else
                        % Multinomial draw to determine behavior state
                        tempmn = mnrnd(1,[1/3 1/3 1/3]);

                        % Determine direction of behavior state from 
                        % the draw (1st element 1 indicates warm clothing
                        % choice, second yields medium clothing choice, 
                        % third yields lower clothing choice
                        if tempmn(1) == 1;
                            OccupantMatrix.BehaviorStatesVector(p) = -1;
                        elseif tempmn(3) == 1;
                            OccupantMatrix.BehaviorStatesVector(p) = 1;                    
                        else
                            OccupantMatrix.BehaviorStatesVector(p) = 0;    
                        end         
                    end
                % User-defined logistic regression rule     
                elseif (RuleVector(p) == 2);
                    if (any(...
                            isnan(...
                            group_logisticregression_inter(p,:)))==0)&&...
                            (any(isnan(...
                            group_logisticregression_arrive(p,:)))==0)
                        if size(possibilitiestemp,1)==1;
                            if (...
                                    OccupantMatrix(...
                                    n).OccupancyStateVectorPrevious(...
                                    1) == 0)||(OccupantMatrix(...
                                    n).OccupancyStateVectorPrevious(...
                                    1) == 255)
                                % Probability of behavior being 'on/open'
                                % upon arrival at the office
                                probon = (exp(...
                                    group_logisticregression_arrive(p,1)+...
                                    (group_logisticregression_arrive(p,2)*...
                                    TOp)+...
                                    (group_logisticregression_arrive(p,3)*...
                                    (OccupantMatrix.OutdoorEnvironmentVector(...
                                    1)))))/(1+(...
                                    exp(group_logisticregression_arrive(...
                                    p,1)+(group_logisticregression_arrive(...
                                    p,2)*TOp)+(...
                                    group_logisticregression_arrive(p,3)*...
                                    (OccupantMatrix.OutdoorEnvironmentVector(...
                                    1))))));            
                                tempbinom = binornd(1,probon);
                            else
                                % Probability of behavior being 'on/open'
                                % during intermediate time at the office 
                                probon = (exp(...
                                    group_logisticregression_inter(...
                                    p,1)+(...
                                    group_logisticregression_inter(p,2)*...
                                    TOp)+(...
                                    group_logisticregression_inter(p,3)*...
                                    (OccupantMatrix.OutdoorEnvironmentVector(...
                                    1)))))/(1+(exp(...
                                    group_logisticregression_inter(p,1)+...
                                    (group_logisticregression_inter(p,2)*...
                                    TOp)+(group_logisticregression_inter(...
                                    p,3)*(...
                                    OccupantMatrix.OutdoorEnvironmentVector(...
                                    1))))));            
                                tempbinom = binornd(1,probon);
                            end
                            
                            % Case where positive behavior state is drawn
                            if tempbinom ==1
                                % Determine direction of behavior state
                                if OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                        1,p) > 0; 
                                    OccupantMatrix.BehaviorStatesVector(...
                                        p) = -1;
                                else
                                    OccupantMatrix.BehaviorStatesVector(...
                                        p) = 1;
                                end
                            else
                                    OccupantMatrix.BehaviorStatesVector(...
                                        p) = 0;
                            end               
                        end            
                    end
                % Humphreys algorithm behavior rule  
                elseif (RuleVector(p) == 3);
                    if (any(isnan(...
                            group_logisticregression_inter(p,:)))==0)&&...
                            (any(isnan(group_logisticregression_arrive(...
                            p,:)))==0)
                        % Case where a 'too warm' action has been simulated
                        % under the Humphrey's behavior algorithm
                        if OccupantMatrix.HumphreysPMVact == 1                               
                            % Case where no 'too cold' actions have already
                            % been taken and 'too warm' action is available
                            if (OccupantMatrix.BehaviorStatesVector(...
                                    p) == 0)...
                                    && (...
                                    OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                    1,p) > 0);
                                % Arrival behavior 'on/open' probability
                                if (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 0)||...
                                        (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 255)
                                    probon = (exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*...
                                        (OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'on/open' state
                                    actionon = binornd(1,probon);
                                % Intermediate behavior 'on/open' probability
                                else
                                    probon = (exp(...
                                        group_logisticregression_inter(...
                                        p,1)+(...
                                        group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_inter(...
                                        p,1)+(...
                                        group_logisticregression_inter(p,2)...
                                        *TOp)+(...
                                        group_logisticregression_inter(p,3)*...
                                        (OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'on/open' state
                                    actionon = binornd(1,probon);
                                end
                                % Case where behavior 'on/open' state has
                                % been drawn
                                if actionon == 1;
                                    OccupantMatrix.BehaviorStatesVector(...
                                        p) = -1;
                                    OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                        1,p) = 0;
                                end
                            % Case where previous 'too cold' action must be
                            % reversed    
                            elseif OccupantMatrix.BehaviorStatesVector(p) ...
                                    == 1;
                                % Arrival behavior 'off/closed' probability
                                if (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 0)||...
                                        (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 255)
                                    probon = (exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'off/closed' state
                                    actionoff = binornd(1,(1-probon));
                                % Intermediate behavior 'off/closed' probability
                                else
                                    probon = (exp(...
                                        group_logisticregression_inter(...
                                        p,1)+(...
                                        group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_inter(...
                                        p,1)+(...
                                        group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    actionoff = binornd(1,(1-probon));
                                end
                                % Case where behavior 'off/closed' state has
                                % been drawn
                                if actionoff == 1;
                                    OccupantMatrix.BehaviorStatesVector(...
                                        p) = 0;
                                    OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                        1,p) = ...
                                        OccupantMatrix.InitialBehaviorPossibilitiesMatrix(...
                                        1,p);
                                end
                            end
                        % Case where a 'too cold' action has been simulated
                        % under the Humphrey's behavior algorithm    
                        elseif OccupantMatrix.HumphreysPMVact == -1
                            if (OccupantMatrix.BehaviorStatesVector(p) == ...
                                    0) && ...
                                    (OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                    2,p) > 0); 
                                if (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 0)||...
                                        (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 255)
                                    % Arrival behavior 'on/open' 
                                    % probability
                                    probon = (...
                                        exp(group_logisticregression_arrive(...
                                        p,1)+...
                                        (group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'on/open' state
                                    actionon = binornd(1,probon);
                                else
                                    % Intermediate behavior 'on/open' 
                                    % probability
                                    probon = (exp(...
                                        group_logisticregression_inter(...
                                        p,1)+...
                                        (group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+...
                                        (exp(...
                                        group_logisticregression_inter(...
                                        p,1)+(...
                                        group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'on/open' state
                                    actionon = binornd(1,probon);
                                end
                                % Case where behavior 'on/open' state has
                                % been drawn
                                if actionon == 1;
                                    OccupantMatrix.BehaviorStatesVector(p) ...
                                        = 1;
                                    OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                        1,p) = 0;
                                end 
                            elseif OccupantMatrix.BehaviorStatesVector(p) == ...
                                    -1;   
                                if (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 0)||...
                                        (OccupantMatrix(...
                                        n).OccupancyStateVectorPrevious(...
                                        1) == 255)
                                    % Arrival behavior 'off/closed' 
                                    % probability
                                    probon = (exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_arrive(...
                                        p,1)+(...
                                        group_logisticregression_arrive(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_arrive(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'off/closed' state
                                    actionoff = binornd(1,(1-probon));
                                else
                                    % Intermediate behavior 'off/closed' 
                                    % probability
                                    probon = (exp(...
                                        group_logisticregression_inter(p,1)...
                                        +(group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(...
                                        p,3)*(...
                                        OccupantMatrix.OutdoorEnvironmentVector(...
                                        1)))))/(1+(exp(...
                                        group_logisticregression_inter(p,1)+...
                                        (group_logisticregression_inter(...
                                        p,2)*TOp)+(...
                                        group_logisticregression_inter(p,3)*...
                                        (OccupantMatrix.OutdoorEnvironmentVector(...
                                        1))))));            
                                    % Draw behavior 'off/closed' state
                                    actionoff = binornd(1,(1-probon));
                                end
                                % Case where behavior 'off/closed' state
                                % has been drawn
                                if actionoff == 1;
                                    OccupantMatrix.BehaviorStatesVector(p) = ...
                                        0;                       
                                    OccupantMatrix.BehaviorPossibilitiesMatrix(...
                                        1,p) = ...
                                        OccupantMatrix.InitialBehaviorPossibilitiesMatrix(...
                                        1,p);
                                end                         
                            end
                        end
                    end
                end
            end   
        end   
    end 
end

%% Run agent-based behavior rules

% Execute any agent-based rule for available behaviors
if any(RuleVector >= 4)    
    % Reset behavior action iteration to 1 for the time step  
    iternumtimestep = 0;      
    % Occupant adjusts once, then can continue and/or reverse action up to
    % 3 times until comfortable or no more options
    maxit = 1; 
    
    % Run the agent-based behavior routine 
    OccupantMatrix = AgentsBehave(OccupantMatrix,...
        postpredmat_sens,controls,SocialMatrix, closetting,Season,trm);
    % Update number of iterations
    iternumtimestep = iternumtimestep + 1;

%     % Rerun agent-based behavior routine until either comfort is ...
%     % satisfied, no more actions are possible/chosen, or maximum ...
%     % behavior action iterations for the time step are reached
%     while (OccupantMatrix.PMVact ~= 0) && ...
%             (OccupantMatrix.WhichPMVact ~= 0) && ...
%             (iternumtimestep < maxit);
%         % Run the agent-based behavior routine
%         OccupantMatrix = AgentsBehave(OccupantMatrix,...
%             postpredmat_sens,controls,SocialMatrix,closetting,Season,trm);
%         % Update number of iterations
%         iternumtimestep = iternumtimestep + 1;
%     end    
end
end
    