function DATA = MainProc
HideCursor
RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock)));

format bank; %output data in easy to read format

subNum = input('Enter subject number ---> ');

%check if this subject and session has been run
app_home = cd;
cd(app_home); 
filename = ['S', int2str(subNum)];
filePath = strcat(app_home,'\DATA\',filename);
if exist(strcat(filePath,'.mat'), 'file') > 0
    strcat(filename, ' already exists - check program parameters and try again.')
    return
end

DATA = [];
save(filePath,'DATA','-v7.3'); % save DATA structure

clc % clear screen 
disp(['S', int2str(subNum)]); %diplay conditions/subnum

% write subject details
age = input('Enter your age ---> ');
sex = input('Enter your gender (m/f/other) ---> ', 's' );
hand = input('Are you right or left handed? (r/l) ---> ','s');
language = input('Is English your first language? (y/n) ---> ','s');
start_time = datestr(now,0);
DATA.details = {age sex hand language start_time};

KbName('UnifyKeyNames');    % Important for some reason to standardise keyboard input across platforms / OSs.

% screen setup
res=[1920 1080];
midx = res(1)/2;
midy = res(2)/2;

% get patterns and trial details from passed pattern array

subData = makePats(30,1,1);
Pats = subData{1,1}(:,:,:,1);
TT = subData{1,2}(:,:,1);

DATA.patterns = Pats;

global Tpos
Tpos = subData{1,3};
global TCols
TCols = subData{1,4};

% experiment parameters
hardDs = 1; % hard/offset distractors?
iti_time = 1;
fix_time = 0.5;
cue_time = 1;
fb_time = 3;
responseTimeout = 6;
cuedTrialsStart = 161;

% grid coordinates for placing stimuli
x = (70:80:950)+420;
y = 70:80:950;

% draw stimuli
lineCol = [0 0 0];
backCol = [150 150 150];
penWidth = 4;

% set MainWindow for PTB drawing
MainWindow = Screen('OpenWindow',0, backCol,[0 0 res(1) res(2)]); % a PTB window to draw into

% L stim (drawn at 0 degrees rotation)
Lstim = Screen('OpenOffscreenWindow', MainWindow, backCol, [0 0 60 60]);
if hardDs == 1
    Screen('DrawLine', Lstim, lineCol, 14, 10, 14, 50, penWidth);
else
    Screen('DrawLine', Lstim, lineCol, 10, 10, 10, 50, penWidth);
end
Screen('DrawLine', Lstim, lineCol, 8, 50, 50, 50, penWidth);

% T stim (drawn at 0 degrees rotation)
Tstim = Screen('OpenOffscreenWindow', MainWindow, backCol, [0 0 60 60]);
Screen('DrawLine', Tstim, lineCol, 30, 10, 30, 50, penWidth);
Screen('DrawLine', Tstim, lineCol, 10, 10, 50, 10, penWidth);

% Fixation cross
Fixation = Screen('OpenOffscreenWindow', MainWindow, backCol, [0 0 60 60]);
Screen('DrawLine', Fixation, [255 255 255], 30, 20, 30, 40, penWidth);
Screen('DrawLine', Fixation, [255 255 255], 20, 30, 40, 30, penWidth);

% Arrow stimulus 
Arrow = Screen('OpenOffscreenWindow', MainWindow, backCol, [0 0 60 60]);
Screen('DrawLine', Arrow, [255 255 255], 30, 0, 30, 60, penWidth);
Screen('DrawLine', Arrow, [255 255 255], 0, 30, 30, 0, penWidth);
Screen('DrawLine', Arrow, [255 255 255], 30, 0, 60, 30, penWidth);

% Instructions
for i = [1:3 5:9]
    Ftext = strcat('Instructions CCR01/Slide',int2str(i),'.JPG');
    instStim(i) =Screen('MakeTexture', MainWindow, double(imread(Ftext)));
end
if rem(subNum,2) == 1
    %odd numbered participants - pre-trial prompt
    Ftext = strcat('Instructions CCR01/Slide4a.JPG');
else
    % even numbered participants - no prompt
    Ftext = strcat('Instructions CCR01/Slide4b.JPG');
end
% make instruction 4
instStim(4) =Screen('MakeTexture', MainWindow, double(imread(Ftext)));

debriefScreen = instStim(6);
errorFB = instStim(7);
errorTO = instStim(8);
restScreen = instStim(9);

% variables used in procedure
restBreak = 80;

% load instructions slides here
RestrictKeysForKbCheck(32); % space bar
for i = 1:5
    if i == 5
        RestrictKeysForKbCheck(112); % F1 key
    end
    Screen('DrawTexture', MainWindow, instStim(i));
    Screen('Flip', MainWindow);
    [~, ~] = accKbWait;
end

% START OF MAIN PROCEDURE
targetLoc = 0;
restcnt = 0;
orientCnt = 0;
totalPoints = 0;

for trial = 1:size(TT,1)
    
    restcnt = restcnt + 1;
    if restcnt > restBreak
        restcnt = 0;
        Screen('DrawTexture', MainWindow, restScreen);
        Screen('Flip', MainWindow);
        WaitSecs(30);
    end
       
    % left/right response randomisation
    orientCnt = rem(orientCnt,16);
    if orientCnt == 0
        Torient = [90*ones(1,8) 270*ones(1,8)];
        Torient = Torient(randperm(16));
    end
    orientCnt = orientCnt + 1;
    
    Screen('Flip', MainWindow);
    WaitSecs(iti_time); %blank screen for 1 sec
    
    % determine trial type
    if TT(trial,4) <= 2
        highReward = 1;
        bonus = 10;
        preTrialText = '10x BONUS trial!';
        pointsCol = [0 220 0];
    else
        highReward = 0;
        bonus = 1;
        preTrialText = 'Normal trial';
        pointsCol = [255 255 255];
    end
    
    % b/s manipulaton of pre-trial information
    if rem(subNum,2) == 1
        Screen('TextSize', MainWindow, 50);
        DrawFormattedText(MainWindow, preTrialText, 'center', midy, pointsCol);
        Screen('Flip', MainWindow);
        WaitSecs(1)
    else
        Screen('TextSize', MainWindow, 50);
        DrawFormattedText(MainWindow, '------', 'center', midy, [255 255 255]);
        Screen('Flip', MainWindow);
        WaitSecs(1)   
    end
    
    Screen('Flip', MainWindow);
    WaitSecs(iti_time); %blank screen for 1 sec
    Screen('DrawTexture', MainWindow, Fixation); % Fixation stimulus
    Screen('Flip', MainWindow);
    WaitSecs(fix_time); % fixation on for 0.5 sec

    %get pattern from Pat array
    curPat = Pats(TT(trial,4),:,TT(trial,5));        
    
    % reshape as 12 x 12 grid
    curPat = reshape(curPat,6,24)';
    curPat = [curPat(1:12,:) curPat(13:24,:)];
    % these are used for identifying the target position
    i = reshape(1:36,6,6)';
    locs = [i i+72 ; i+36 i+108]; 
    
    tLoc = find(curPat==1001);
    
    % display pattern and read keyboard input 
    for i = 1:12
        for k = 1:12
            cellVal = double(curPat(i,k)-1000);
            if cellVal == 1
                % TARGET (random orientation)
                targetLoc = locs(i,k);
                Screen('DrawTexture', MainWindow, Tstim, [], [x(k) y(i) x(k)+60 y(i)+60], Torient(orientCnt)); % T stim
            elseif cellVal > 0
                % DISRACTOR
                rot = (((cellVal-1)/10)-1)*90; % takes 1-4 and coverts to rotation angle (in 90 degrees)
                Screen('DrawTexture', MainWindow, Lstim, [], [x(k) y(i) x(k)+60 y(i)+60], rot); % L stim
            end
        end
    end
    
%     Screen('DrawLine', MainWindow, [255 0 0], 0, 540, 1920, 540, 1); % red gridlines
%     Screen('DrawLine', MainWindow, [255 0 0], 960, 0, 960, 1080, 1); % red gridlines
    
    imgOnTime = Screen('Flip', MainWindow); % display image on screen and record time
    
%     GetImage call. Alter the rect argument to change the location of the screen shot
%     imageArray = Screen('GetImage', MainWindow);
% 
%     imwrite is a Matlab function, not a PTB-3 function
%     imwrite(imageArray, 'screenshot.jpg')
    
    % wait for response
    RestrictKeysForKbCheck([67 78 122]); % wait for response (c, n, or F11)
    [keyCode, keyDown, timeout] = accKbWait(imgOnTime, responseTimeout); % Accurate measure response time, stored as keyDown. If timeout is used specify start time (1) and duration (2).
    RT = 1000 * (keyDown - imgOnTime); % Response time in ms
    choice = find(keyCode==1);
    
    % determine accuracy of the response
    accuracy = 0;
    if numel(choice) == 1 %acc=0 for cases of multiple key presses
        if (choice == 67 && Torient(orientCnt) == 270) || (choice == 78 && Torient(orientCnt) == 90)
            accuracy = 1;
        end
    elseif numel(choice) == 2
        choice = -99;
        accuracy = 0;
        RT = -99;
    else % timeout
        choice = -99;
        accuracy = -99;
        RT = -99;
    end
    
    % F10 to quit program - you might take this out of final version
    if choice == 122
        disp('someone pressed the F11 key')
        break
    end
    
    textRT = [int2str(RT) 'ms'];
    
    trialPoints = (2000 - RT)*bonus;
    
    if accuracy == 0
        trialPointsText = 'Error! - 10000 points';
        trialPoints = -10000;    
    elseif timeout == 1
        trialPointsText = 'Timeout! Too slow - 10000 points';
        trialPoints = -10000; 
    elseif trialPoints < 0
        trialPointsText = 'Too slow, 0 points'; 
        trialPoints = 0;
    elseif highReward == 1
        trialPointsText = [int2str(bonus) 'x bonus! +' int2str(trialPoints)];
    elseif highReward == 0
        trialPointsText = ['+' int2str(trialPoints)];
    end
    
    totalPoints = totalPoints + trialPoints;
    if totalPoints < 0
        totalPoints = 0;
    end    
    totalPointsText = ['TOTAL = ' int2str(totalPoints)];
    
    Screen('TextSize', MainWindow, 50);
    DrawFormattedText(MainWindow, trialPointsText, 'center', midy-50, pointsCol); 
    Screen('Flip', MainWindow, [], 1);
    WaitSecs(1)
    
    Screen('TextSize', MainWindow, 50);
    DrawFormattedText(MainWindow, totalPointsText, 'center', midy+50, [255 255 255]);
    Screen('Flip', MainWindow);
    WaitSecs(1)
    
%     % check for any error messages to display
%     if accuracy == 0
%         Screen('DrawTexture', MainWindow, errorFB);
%         Screen('Flip', MainWindow);
%         WaitSecs(fb_time);
%     elseif timeout == 1
%         Screen('DrawTexture', MainWindow, errorTO);
%         Screen('Flip', MainWindow);
%         WaitSecs(fb_time);
%     end
    
    %write trial data to the file
    DATA.trial_data(trial,1) = subNum;
    DATA.trial_data(trial,2) = datenum(datetime('now'));
    DATA.trial_data(trial,3:8) = TT(trial,:);
    DATA.trial_data(trial,9) = targetLoc;
    DATA.trial_data(trial,10) = Torient(orientCnt);
    DATA.trial_data(trial,11) = choice;
    DATA.trial_data(trial,12) = accuracy;
    DATA.trial_data(trial,13) = RT; %RT
    DATA.trial_data(trial,14) = trialPoints;
    DATA.trial_data(trial,15) = totalPoints;

    save(filePath,'DATA'); %save DATA structure
       
end
% 
% % START OF AWARENESS TASK
% targetLoc = 0;
% orientCnt = 0;
% displayTime = 5; % time that pattern is on the screen
% responseTimeout = 10; % new timeout length for awareness task
% awareBlocks = 4;
% 
% % generate order for awareness
% patList = [1 1; 1 2; 1 3; 1 4; 3 1; 3 2; 3 3; 3 4];
% orderAware = zeros(awareBlocks*8, 2); % holds the list of trials
% bStarts = 1:8:8*awareBlocks;
% for b = 1:awareBlocks
%     orderCheck = false;
%     while orderCheck == false
%         blockOrder = randperm(8);
%         orderAware(bStarts(b):bStarts(b)+7,:) = patList(blockOrder,:);
%         if b > 1 % check repetition across blocks
%             if orderAware(bStarts(b),1) ~= orderAware(bStarts(b)-1,1) || orderAware(bStarts(b),2) ~= orderAware(bStarts(b)-1,2)
%                 orderCheck = true; % other blocks pass check
%             end
%         else
%             orderCheck = true; % first block 
%         end
%     end
% end
%    
% % load instructions slides here
% RestrictKeysForKbCheck(32); % space bar
% for i = 5:6
%     if i == 6
%         RestrictKeysForKbCheck(112); % F1 key
%     end
%     Screen('DrawTexture', MainWindow, instStim(i));
%     Screen('Flip', MainWindow);
%     [~, ~] = accKbWait;
% end
% 
% for trial = 1:size(orderAware,1)
%        
%     % left/right response randomisation
%     orientCnt = rem(orientCnt,16);
%     if orientCnt == 0
%         Torient = [90*ones(1,8) 270*ones(1,8)];
%         Torient = Torient(randperm(16));
%     end
%     orientCnt = orientCnt + 1;    
%     
%     %RSI
%     Screen('Flip', MainWindow);
%     WaitSecs(iti_time); %blank screen for 1 sec
%     Screen('DrawTexture', MainWindow, Fixation); % Fixation stimulus
%     Screen('Flip', MainWindow);
%     WaitSecs(fix_time); % fixation on for 0.5 sec
% 
%     % get pattern from Pat array
%     curPat = Pats(orderAware(trial,1),:,orderAware(trial,2));    
%     
%     % reshape as 12 x 12 grid
%     curPat = reshape(curPat,6,24)';
%     curPat = [curPat(1:12,:) curPat(13:24,:)];
%     i = reshape(1:36,6,6)';
%     locs = [i i+72 ; i+36 i+108];    
% 
%     % display pattern and read keyboard input 
%     for i = 1:12
%         for k = 1:12
%             cellVal = double(curPat(i,k)-1000);
%             if cellVal == 1
%                 % TARGET (random orientation)
%                 targetLoc = locs(i,k);
%                 Screen('DrawTexture', MainWindow, Tstim, [], [x(k) y(i) x(k)+60 y(i)+60], Torient(orientCnt)); % T stim
%             elseif cellVal > 0
%                 % DISRACTOR
%                 rot = (((cellVal-1)/10)-1)*90; % takes 1-4 and coverts to rotation angle (in 90 degrees)
%                 Screen('DrawTexture', MainWindow, Lstim, [], [x(k) y(i) x(k)+60 y(i)+60], rot); % L stim
%             end
%         end
%     end
% 
%     imgOnTime = Screen('Flip', MainWindow); % display image on screen and record time
%     
%     WaitSecs(displayTime);
%     
%     Screen('DrawTexture', MainWindow, oldNewPrompt);
%     Screen('Flip', MainWindow);
% 
%     % wait for response
%     RestrictKeysForKbCheck([38 40 122]); % wait for response (up, down, or F11)
%     [keyCode, keyDown, timeout] = accKbWait(imgOnTime, responseTimeout); % Accurate measure response time, stored as keyDown. If timeout is used specify start time (1) and duration (2).
%     RT = 1000 * (keyDown - imgOnTime); % Response time in ms
%     choice = find(keyCode==1);
%     
%     % F10 to quit program - you might take this out of final version
%     if choice == 122
%         disp('someone pressed the F11 key')
%         break
%     end
%     
%     if timeout == 1
%         Screen('DrawTexture', MainWindow, errorTO);
%         Screen('Flip', MainWindow);
%         WaitSecs(fb_time);
%         accuracy = 9999;
%         choice = 9999;
%     else % real response made, determine accuracy
%         accuracy = 0;
%         if orderAware(trial,1) == 1 && choice == 38
%             accuracy = 1; % hit
%         elseif orderAware(trial,1) == 3 && choice == 40
%             accuracy = 1; % correct rejection
%         end
%     end
%     
%     %write trial data to the file
%     DATA.awareness_data(trial,1:3) = [trial orderAware(trial,:)];
%     DATA.awareness_data(trial,4) = targetLoc;
%     DATA.awareness_data(trial,5) = Torient(orientCnt);
%     DATA.awareness_data(trial,6) = choice;
%     DATA.awareness_data(trial,7) = accuracy;
%     DATA.awareness_data(trial,8) = RT; 
% 
%     save(filePath,'DATA'); %save DATA structure
%        
% end

% Debrief screen
Screen('DrawTexture', MainWindow, debriefScreen, [], []); % Instruction 1
Screen(MainWindow, 'Flip');
RestrictKeysForKbCheck(122); % F11
[~,~,~] = accKbWait;

% show final points total
Screen('TextSize', MainWindow, 50);
DrawFormattedText(MainWindow, totalPointsText, 'center', midy+50, [255 255 255]);
Screen('Flip', MainWindow);
RestrictKeysForKbCheck(122); % F11
[~,~,~] = accKbWait;

ShowCursor
clear
sca

end

