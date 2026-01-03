function blackjack()
% BLACKJACK  Play a simple interactive Blackjack game in MATLAB (command-line).
% - Player vs dealer
% - Dealer stands on 17 or higher (soft 17 treated as 17 and stands)
% - Natural blackjack payout not tracked with money; just immediate win/push/lose
% - Good sound on player win, bad sound on player lose, neutral on push
%
% Save as blackjack.m and run in MATLAB.

    clc;
    rng('shuffle'); % randomize shuffle
    fprintf('Welcome to MATLAB Blackjack!\n\n');

    while true
        deck = makeDeck();
        deck = shuffleDeck(deck);

        % Deal initial hands
        playerHand = {drawCard()};
        dealerHand = {drawCard()};
        playerHand{end+1} = drawCard();
        dealerHand{end+1} = drawCard();

        fprintf('--- New Round ---\n');
        fprintf('Dealer shows: %s\n', cardStr(dealerHand{1}));
        fprintf('Your hand: %s\n', handStr(playerHand));
        fprintf('Your total: %d\n', handValue(playerHand));

        % Check naturals (blackjack)
        playerVal = handValue(playerHand);
        dealerVal = handValue(dealerHand);
        if playerVal == 21 && dealerVal == 21
            fprintf('Both have blackjack! Push.\n');
            neutralSound();
        elseif playerVal == 21
            fprintf('Blackjack! You win!\n');
            goodSound();
        elseif dealerVal == 21
            fprintf('Dealer has blackjack (%s %s). You lose.\n', cardStr(dealerHand{1}), cardStr(dealerHand{2}));
            badSound();
        else
            % Player turn
            playerBusted = false;
            while true
                cmd = input('Hit (h) or Stand (s)? ','s');
                if isempty(cmd), cmd = 's'; end
                cmd = lower(cmd(1));
                if cmd == 'h'
                    newCard = drawCard();
                    playerHand{end+1} = newCard;
                    fprintf('You drew: %s\n', cardStr(newCard));
                    pv = handValue(playerHand);
                    fprintf('Your hand: %s  (total %d)\n', handStr(playerHand), pv);
                    if pv > 21
                        fprintf('You busted! (%d)\n', pv);
                        playerBusted = true;
                        break;
                    elseif pv == 21
                        fprintf('You have 21. Standing.\n');
                        break;
                    end
                elseif cmd == 's'
                    fprintf('You stand with %d.\n', handValue(playerHand));
                    break;
                else
                    fprintf('Type h to hit or s to stand.\n');
                end
            end

            % Dealer turn (if player didn't bust)
            if ~playerBusted
                fprintf('\nDealer''s turn. Dealer reveals %s and %s\n', cardStr(dealerHand{1}), cardStr(dealerHand{2}));
                fprintf('Dealer total: %d\n', handValue(dealerHand));
                while true
                    dv = handValue(dealerHand);
                    % Dealer stands on 17 or higher (including soft 17)
                    if dv < 17
                        newCard = drawCard();
                        dealerHand{end+1} = newCard;
                        fprintf('Dealer hits and gets %s. Dealer total now %d\n', cardStr(newCard), handValue(dealerHand));
                    else
                        fprintf('Dealer stands with %d.\n', dv);
                        break;
                    end
                    if handValue(dealerHand) > 21
                        fprintf('Dealer busted! (%d)\n', handValue(dealerHand));
                        break;
                    end
                end
            end

            % Resolve
            pval = handValue(playerHand);
            dval = handValue(dealerHand);

            fprintf('\nFinal hands:\n');
            fprintf('You: %s  (%d)\n', handStr(playerHand), pval);
            fprintf('Dealer: %s  (%d)\n\n', handStr(dealerHand), dval);

            if playerBusted
                fprintf('You lose this round.\n');
                badSound();
            elseif dval > 21
                fprintf('Dealer busted — you win!\n');
                goodSound();
            elseif pval > dval
                fprintf('You win!\n');
                goodSound();
            elseif pval < dval
                fprintf('You lose.\n');
                badSound();
            else
                fprintf('Push (tie).\n');
                neutralSound();
            end
        end

        again = input('\nPlay another round? (y to continue, any other key to quit): ','s');
        if isempty(again) || lower(again(1)) ~= 'y'
            fprintf('Thanks for playing Blackjack. Goodbye!\n');
            break;
        end
        clc;
    end

    % --- Nested helper functions ------------------------------------------------
    function deck = makeDeck()
        suits = {'♠','♥','♦','♣'};
        ranks = {'A','2','3','4','5','6','7','8','9','10','J','Q','K'};
        deck = cell(52,1);
        idx = 1;
        for si = 1:4
            for ri = 1:13
                rank = ranks{ri};
                suit = suits{si};
                val = ri; % temp
                if ri == 1
                    value = 1; % Ace special (1 or 11)
                elseif ri >= 11
                    value = 10;
                else
                    value = ri;
                end
                card.rank = rank;
                card.suit = suit;
                card.value = value;
                deck{idx} = card;
                idx = idx + 1;
            end
        end
    end

    function d = shuffleDeck(d)
        n = numel(d);
        perm = randperm(n);
        d = d(perm);
    end

    function c = drawCard()
        % drawCard removes top card from deck and returns it (and updates deck)
        % We'll simulate by taking a random card from remaining deck each call.
        % To avoid global deck pointer complexity, just draw uniformly and
        % remove from deck cell array in surrounding scope by using nested functions
        persistent currentDeck;
        if isempty(currentDeck)
            currentDeck = deck;
        end
        if isempty(currentDeck)
            currentDeck = makeDeck();
            currentDeck = shuffleDeck(currentDeck);
        end
        c = currentDeck{end};
        currentDeck(end) = [];
        deck = currentDeck; % update outer deck variable
        % If we emptied deck, reset persistent so next round will prepare new deck
        if isempty(currentDeck)
            currentDeck = [];
        end
    end

    function s = cardStr(c)
        s = sprintf('%s%s', c.rank, c.suit);
    end

    function s = handStr(hand)
        parts = cellfun(@cardStr, hand, 'UniformOutput', false);
        s = strjoin(parts, ' ');
    end

    function val = handValue(hand)
        % Returns best blackjack value for a hand (Ace counted as 1 or 11 optimally)
        values = cellfun(@(c)c.value, hand);
        total = sum(values);
        numAces = sum(cellfun(@(c)strcmp(c.rank,'A'), hand));
        % try to add 10 (turn Ace from 1 to 11) while it doesn't bust
        for k = 1:numAces
            if total + 10 <= 21
                total = total + 10;
            end
        end
        val = total;
    end

    function goodSound()
    % Pleasant short melody (three notes ascending triad + flourish)
    fs = 44100;
    y = [];

    y = [y; tone(440,0.15,fs)];      % A4
    y = [y; tone(554.37,0.12,fs)];   % C#5
    y = [y; tone(659.25,0.25,fs)];   % E5

    % quick arpeggio flourish
    y = [y; tone(880,0.08,fs)];
    y = [y; tone(659.25,0.06,fs)];

    % tiny fade
    y = y .* linspace(1,0.85,length(y))';

    sound(y,fs);
end


    function badSound()
        % Buzzy descending failure sound
        fs = 44100;
        d1 = 0.22; d2 = 0.16;
        y = [];
        y = [y; buzztone(220,d1,fs)];
        y = [y; buzztone(180,d2,fs)];
        y = [y; buzztone(140,0.12,fs)];
        sound(y,fs);
    end

    function neutralSound()
        % A polite short beep
        fs = 44100;
        y = tone(440,0.18,fs);
        sound(y,fs);
    end

    function s = tone(freq, dur, fs)
        t = (0:1/fs:dur)';
        s = sin(2*pi*freq*t) .* envelope(length(t));
    end

    function s = buzztone(freq, dur, fs)
        % buzzy tone by adding harmonics and square-ish ring
        t = (0:1/fs:dur)';
        s = sin(2*pi*freq*t) + 0.6*sin(2*pi*freq*2.*t) + 0.3*sin(2*pi*freq*3.*t);
        s = s .* envelope(length(t));
        % distort a bit
        s = s .* (1 - 0.6 * tanh(4*s));
    end

    function env = envelope(N)
        % simple attack-release envelope
        attack = round(0.05 * N);
        release = round(0.05 * N);
        sustain = N - attack - release;
        if sustain < 1
            attack = round(N/2);
            release = N - attack;
            sustain = 0;
        end
        env = [linspace(0,1,attack), ones(1,sustain), linspace(1,0,release)];
        env = env(:);
    end

end
