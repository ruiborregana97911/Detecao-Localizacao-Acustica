




function my_beep(channel)
    Fs=48000;
    dur=0.25;
    t=linspace(0,dur,dur*Fs);
    s=sin(2*pi*t*500);
    
    if channel==1
        out=[zeros(size(s)) ;s]';   %right
        sound(out,Fs);
    elseif channel==2
        out=[s ;zeros(size(s))]';   %left
        sound(out,Fs);
    end

end







